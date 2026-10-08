// Small App Store Connect API client, without extra dependencies.
//
//   node store/asc.mjs GET /v1/apps
//   node store/asc.mjs PATCH /v1/... '{"data": ...}'
//
// Auth: API key ansible/AuthKey_<KEY ID>.p8 (git-ignored), see ansible/README or the
// TestFlight upload; key id and issuer id below are identifiers, not secrets.
import { createPrivateKey, sign } from 'node:crypto';
import { readFileSync } from 'node:fs';

const keyId = 'T2SAQNG77D';
const issuerId = '34dc8291-a393-45fc-bad5-0fd1b0c5aad4';
const keyFile = new URL(`../ansible/AuthKey_${keyId}.p8`, import.meta.url);
const api = 'https://api.appstoreconnect.apple.com';

/** A JWT for the App Store Connect API, valid for 15 minutes. */
export function token() {
  const encode = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const header = encode({ alg: 'ES256', kid: keyId, typ: 'JWT' });
  const payload = encode({ iss: issuerId, iat: now, exp: now + 900, aud: 'appstoreconnect-v1' });
  const key = createPrivateKey(readFileSync(keyFile));
  const signature = sign('sha256', Buffer.from(`${header}.${payload}`), { key, dsaEncoding: 'ieee-p1363' });
  return `${header}.${payload}.${signature.toString('base64url')}`;
}

/** Calls the API; returns the parsed JSON (or null for an empty answer), throws on an error. */
export async function call(method, path, body) {
  const response = await fetch(path.startsWith('http') ? path : api + path, {
    method,
    headers: { Authorization: `Bearer ${token()}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${method} ${path}: ${response.status} ${text}`);
  return text ? JSON.parse(text) : null;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const [method, path, body] = process.argv.slice(2);
  const result = await call(method, path, body === undefined ? undefined : JSON.parse(body));
  console.log(JSON.stringify(result, null, 2));
}
