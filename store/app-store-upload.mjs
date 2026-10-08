// Puts texts, screenshots and the build from store/app-store.md and store/screenshots/ios/
// into the App Store version being edited (created if there is none). Does not submit.
//
//   node store/app-store-upload.mjs <version> <build number>
//   node store/app-store-upload.mjs 1.5.13 61
import { createHash } from 'node:crypto';
import { readFileSync, readdirSync } from 'node:fs';
import { call } from './asc.mjs';

const appId = '6478289375';
const [versionString, buildNumber] = process.argv.slice(2);
if (!versionString || !buildNumber) {
  console.error('usage: node store/app-store-upload.mjs <version> <build number>');
  process.exit(1);
}

// --- texts from app-store.md: the code block after each bold field name, per language section
const markdown = readFileSync(new URL('app-store.md', import.meta.url), 'utf8');

function field(section, name) {
  const start = markdown.indexOf(`## ${section}`);
  const label = markdown.indexOf(`**${name}**`, start);
  const open = markdown.indexOf('```\n', label) + 4;
  const close = markdown.indexOf('\n```', open);
  if (start < 0 || label < 0) throw new Error(`no field "${name}" in section "${section}"`);
  return markdown.slice(open, close);
}

function checkLength(locale, name, text, max) {
  if (text.length > max) throw new Error(`${locale} ${name}: ${text.length} characters, at most ${max}`);
  return text;
}

const shared = {
  supportUrl: 'https://github.com/freegroup/candle',
  marketingUrl: 'https://freegroup.github.io/candle/',
  privacyPolicyUrl: 'https://freegroup.github.io/candle/',
  copyright: '2026 Andreas Herz',
};

const texts = {
  'de-DE': {
    name: field('Deutsch', 'Name'),
    subtitle: field('Deutsch', 'Untertitel'),
    promotionalText: field('Deutsch', 'Werbetext'),
    keywords: field('Deutsch', 'Stichwörter'),
    description: field('Deutsch', 'Beschreibung'),
    whatsNew: field('Deutsch', 'Neu in dieser Version'),
  },
  'en-US': {
    name: field('English', 'Name'),
    subtitle: field('English', 'Subtitle'),
    promotionalText: field('English', 'Promotional text'),
    keywords: field('English', 'Keywords'),
    description: field('English', 'Description'),
    whatsNew: field('English', "What's new"),
  },
};

// the first code block of a section without field names, e.g. the review notes
function block(section) {
  const start = markdown.indexOf(`## ${section}`);
  if (start < 0) throw new Error(`no section "${section}"`);
  const open = markdown.indexOf('```\n', start) + 4;
  return markdown.slice(open, markdown.indexOf('\n```', open));
}

const reviewNotes = block('Hinweise für die Prüfung');

for (const [locale, text] of Object.entries(texts)) {
  checkLength(locale, 'name', text.name, 30);
  checkLength(locale, 'subtitle', text.subtitle, 30);
  checkLength(locale, 'promotional text', text.promotionalText, 170);
  checkLength(locale, 'keywords', text.keywords, 100);
  checkLength(locale, 'description', text.description, 4000);
  checkLength(locale, "what's new", text.whatsNew, 4000);
}

// --- the version being edited
async function editableVersion() {
  const versions = await call('GET', `/v1/apps/${appId}/appStoreVersions?filter[platform]=IOS&limit=10`);
  const editable = versions.data.find((v) =>
    ['PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED'].includes(v.attributes.appStoreState));
  if (editable) {
    if (editable.attributes.versionString !== versionString) {
      await call('PATCH', `/v1/appStoreVersions/${editable.id}`, {
        data: { type: 'appStoreVersions', id: editable.id, attributes: { versionString } },
      });
    }
    return editable.id;
  }
  const created = await call('POST', '/v1/appStoreVersions', {
    data: {
      type: 'appStoreVersions',
      attributes: { platform: 'IOS', versionString },
      relationships: { app: { data: { type: 'apps', id: appId } } },
    },
  });
  return created.data.id;
}

const versionId = await editableVersion();
console.log(`version ${versionString}: ${versionId}`);

await call('PATCH', `/v1/appStoreVersions/${versionId}`, {
  data: { type: 'appStoreVersions', id: versionId, attributes: { copyright: shared.copyright } },
});

// --- build
const builds = await call('GET',
  `/v1/builds?filter[app]=${appId}&filter[version]=${buildNumber}&filter[preReleaseVersion.platform]=IOS`);
const build = builds.data[0];
if (!build) throw new Error(`no build ${buildNumber}`);
await call('PATCH', `/v1/appStoreVersions/${versionId}/relationships/build`, { data: { type: 'builds', id: build.id } });
console.log(`build ${buildNumber}: ${build.id}`);

// --- version texts per language
const versionLocalizations = (await call('GET', `/v1/appStoreVersions/${versionId}/appStoreVersionLocalizations`)).data;
const localizationIds = {};
for (const [locale, text] of Object.entries(texts)) {
  const attributes = {
    description: text.description,
    keywords: text.keywords,
    promotionalText: text.promotionalText,
    whatsNew: text.whatsNew,
    supportUrl: shared.supportUrl,
    marketingUrl: shared.marketingUrl,
  };
  const existing = versionLocalizations.find((l) => l.attributes.locale === locale);
  if (existing) {
    await call('PATCH', `/v1/appStoreVersionLocalizations/${existing.id}`, {
      data: { type: 'appStoreVersionLocalizations', id: existing.id, attributes },
    });
    localizationIds[locale] = existing.id;
  } else {
    const created = await call('POST', '/v1/appStoreVersionLocalizations', {
      data: {
        type: 'appStoreVersionLocalizations',
        attributes: { locale, ...attributes },
        relationships: { appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } } },
      },
    });
    localizationIds[locale] = created.data.id;
  }
  console.log(`texts ${locale}`);
}

// --- app name, subtitle and privacy policy per language (the app info being edited)
const appInfos = (await call('GET', `/v1/apps/${appId}/appInfos`)).data;
const appInfo = appInfos.find((i) => i.attributes.state !== 'READY_FOR_DISTRIBUTION') ?? appInfos[0];
const infoLocalizations = (await call('GET', `/v1/appInfos/${appInfo.id}/appInfoLocalizations`)).data;
for (const [locale, text] of Object.entries(texts)) {
  const attributes = { name: text.name, subtitle: text.subtitle, privacyPolicyUrl: shared.privacyPolicyUrl };
  const existing = infoLocalizations.find((l) => l.attributes.locale === locale);
  if (existing) {
    await call('PATCH', `/v1/appInfoLocalizations/${existing.id}`, {
      data: { type: 'appInfoLocalizations', id: existing.id, attributes },
    });
  } else {
    await call('POST', '/v1/appInfoLocalizations', {
      data: {
        type: 'appInfoLocalizations',
        attributes: { locale, ...attributes },
        relationships: { appInfo: { data: { type: 'appInfos', id: appInfo.id } } },
      },
    });
  }
  console.log(`name ${locale}: ${text.name}`);
}

// --- notes for App Review; the contact comes from the previous version
async function reviewDetail(id) {
  try {
    return (await call('GET', `/v1/appStoreVersions/${id}/appStoreReviewDetail`)).data;
  } catch {
    return null;
  }
}

const currentDetail = await reviewDetail(versionId);
if (currentDetail) {
  await call('PATCH', `/v1/appStoreReviewDetails/${currentDetail.id}`, {
    data: { type: 'appStoreReviewDetails', id: currentDetail.id, attributes: { notes: reviewNotes, demoAccountRequired: false } },
  });
} else {
  const versions = await call('GET', `/v1/apps/${appId}/appStoreVersions?filter[appStoreState]=READY_FOR_SALE&limit=1`);
  const previous = versions.data[0] && (await reviewDetail(versions.data[0].id));
  const contact = previous ? previous.attributes : {};
  await call('POST', '/v1/appStoreReviewDetails', {
    data: {
      type: 'appStoreReviewDetails',
      attributes: {
        contactFirstName: contact.contactFirstName,
        contactLastName: contact.contactLastName,
        contactPhone: contact.contactPhone,
        contactEmail: contact.contactEmail,
        demoAccountRequired: false,
        notes: reviewNotes,
      },
      relationships: { appStoreVersion: { data: { type: 'appStoreVersions', id: versionId } } },
    },
  });
}
console.log('review notes');

// --- screenshots: the same (German) images for both languages
const screenshotFolders = { APP_IPHONE_67: 'iphone-6.9', APP_IPAD_PRO_3GEN_129: 'ipad-13' };

async function uploadScreenshot(setId, path, fileName) {
  const bytes = readFileSync(path);
  const reserved = await call('POST', '/v1/appScreenshots', {
    data: {
      type: 'appScreenshots',
      attributes: { fileName, fileSize: bytes.length },
      relationships: { appScreenshotSet: { data: { type: 'appScreenshotSets', id: setId } } },
    },
  });
  for (const operation of reserved.data.attributes.uploadOperations) {
    const headers = Object.fromEntries(operation.requestHeaders.map((h) => [h.name, h.value]));
    const part = bytes.subarray(operation.offset, operation.offset + operation.length);
    const response = await fetch(operation.url, { method: operation.method, headers, body: part });
    if (!response.ok) throw new Error(`uploading ${fileName}: ${response.status}`);
  }
  await call('PATCH', `/v1/appScreenshots/${reserved.data.id}`, {
    data: {
      type: 'appScreenshots',
      id: reserved.data.id,
      attributes: { uploaded: true, sourceFileChecksum: createHash('md5').update(bytes).digest('hex') },
    },
  });
}

for (const [locale, localizationId] of Object.entries(localizationIds)) {
  const sets = (await call('GET', `/v1/appStoreVersionLocalizations/${localizationId}/appScreenshotSets`)).data;
  // older sizes copied from the previous version show the old app; Apple scales the new ones down
  for (const set of sets) {
    if (!(set.attributes.screenshotDisplayType in screenshotFolders)) {
      await call('DELETE', `/v1/appScreenshotSets/${set.id}`);
    }
  }
  for (const [displayType, folder] of Object.entries(screenshotFolders)) {
    let set = sets.find((s) => s.attributes.screenshotDisplayType === displayType);
    if (set) {
      const old = (await call('GET', `/v1/appScreenshotSets/${set.id}/appScreenshots`)).data;
      for (const screenshot of old) await call('DELETE', `/v1/appScreenshots/${screenshot.id}`);
    } else {
      set = (await call('POST', '/v1/appScreenshotSets', {
        data: {
          type: 'appScreenshotSets',
          attributes: { screenshotDisplayType: displayType },
          relationships: {
            appStoreVersionLocalization: { data: { type: 'appStoreVersionLocalizations', id: localizationId } },
          },
        },
      })).data;
    }
    const directory = new URL(`screenshots/ios/${folder}/`, import.meta.url);
    const files = readdirSync(directory).filter((f) => f.endsWith('.png')).sort();
    for (const file of files) await uploadScreenshot(set.id, new URL(file, directory), file);
    console.log(`screenshots ${locale} ${displayType}: ${files.length}`);
  }
}

console.log('done - check in App Store Connect, answer "App-Datenschutz" and submit there');
