# Candle server

API for the Candle app. Node 24+ runs the TypeScript sources directly (no build step);
`tsc` only checks types. Deployment: see [../ansible/README.md](../ansible/README.md).

```sh
npm install
cp .env.example .env      # set JWT_SECRET, for simulators also DEBUG_ATTESTATION_TOKEN
npm run dev               # http://127.0.0.1:8080
npm test                  # vitest
npm run typecheck
```

## Installation identity (`src/auth/`)

No login: every installation proves that it is the genuine app on a real device and gets
short-lived tokens. The server stores nothing; the refresh token carries the installation.

1. `POST /v1/auth/challenge` → one-time challenge (5 min, in memory)
2. The app proves itself for `SHA-256(challenge)`:
   iOS with **App Attest** (new key + attestation), Android with **Play Integrity** (standard request,
   requestHash = hex), simulators with `DEBUG_ATTESTATION_TOKEN` (local server only).
3. `POST /v1/auth/register` → `installationId`, `accessToken` (1 h), `refreshToken` (90 days)
4. API calls: `Authorization: Bearer <accessToken>`, e.g. `GET /v1/me`
5. `POST /v1/auth/refresh` with the refresh token **and** a fresh proof for a new challenge
   (iOS: App Attest assertion, Android: new integrity token).

On `401` from refresh (expired, or server rebuilt with a new `JWT_SECRET`) the app discards its
key and registers again.
