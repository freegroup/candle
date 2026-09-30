// Uploads an Android App Bundle to a Google Play track, without extra dependencies.
//
//   node store/play-upload.mjs <track> <path/to/app-release.aab> ["release notes (de-DE)"]
//
// track: internal | alpha (closed test) | beta (open test) | production
// Auth: service account key ansible/google-play-publisher.json (git-ignored), invited in the
// Play Console with "Releases in Test-Tracks verwalten".
import { createSign } from 'node:crypto';
import { readFileSync } from 'node:fs';

const packageName = 'de.freegroup.candle.app';
const keyFile = new URL('../ansible/google-play-publisher.json', import.meta.url);
const api = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}`;
const uploadApi = `https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${packageName}`;

const [track, bundlePath, notes] = process.argv.slice(2);
if (!track || !bundlePath) {
  console.error('usage: node store/play-upload.mjs <track> <app-release.aab> ["release notes"]');
  process.exit(1);
}

/** OAuth access token for the service account (JWT bearer flow). */
async function accessToken() {
  const key = JSON.parse(readFileSync(keyFile, 'utf8'));
  const now = Math.floor(Date.now() / 1000);
  const encode = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
  const unsigned = `${encode({ alg: 'RS256', typ: 'JWT' })}.${encode({
    iss: key.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: key.token_uri,
    iat: now,
    exp: now + 3600,
  })}`;
  const signature = createSign('RSA-SHA256').update(unsigned).sign(key.private_key, 'base64url');
  const response = await fetch(key.token_uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${unsigned}.${signature}`,
    }),
  });
  if (!response.ok) throw new Error(`token: ${response.status} ${await response.text()}`);
  return (await response.json()).access_token;
}

const token = await accessToken();

async function call(method, url, { body, contentType = 'application/json' } = {}) {
  const response = await fetch(url, {
    method,
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': contentType },
    body: contentType === 'application/json' && body ? JSON.stringify(body) : body,
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${method} ${url.replace(api, '').replace(uploadApi, '')}: ${response.status} ${text}`);
  return text ? JSON.parse(text) : {};
}

// All changes happen in an "edit" that is only published by the final commit.
const edit = await call('POST', `${api}/edits`);
try {
  console.log(`uploading ${bundlePath} ...`);
  const bundle = await call('POST', `${uploadApi}/edits/${edit.id}/bundles?uploadType=media`, {
    body: readFileSync(bundlePath),
    contentType: 'application/octet-stream',
  });
  const versionCode = String(bundle.versionCode);
  console.log(`uploaded version code ${versionCode}`);

  await call('PUT', `${api}/edits/${edit.id}/tracks/${track}`, {
    body: {
      track,
      releases: [
        {
          versionCodes: [versionCode],
          status: 'completed',
          ...(notes ? { releaseNotes: [{ language: 'de-DE', text: notes }] } : {}),
        },
      ],
    },
  });
  await call('POST', `${api}/edits/${edit.id}:commit`);
  console.log(`released ${versionCode} to track "${track}"`);
} catch (error) {
  await call('DELETE', `${api}/edits/${edit.id}`).catch(() => {});
  throw error;
}
