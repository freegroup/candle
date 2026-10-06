import type { FastifyInstance } from 'fastify';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.ts';
import { AppAttestVerifier } from '../src/auth/apple.ts';
import { challengeHash } from '../src/auth/challenge_hash.ts';
import { ChallengeStore } from '../src/auth/challenges.ts';
import { type IntegrityPayload, PlayIntegrityVerifier } from '../src/auth/google.ts';
import { TokenService } from '../src/auth/tokens.ts';
import { createDevice, validDate } from './app_attest_fixture.ts';

const secret = new TextEncoder().encode('a-test-secret-with-at-least-32-characters');
const device = await createDevice();

let app: FastifyInstance;
let integrityVerdicts: IntegrityPayload[];

async function buildTestApp(tokenSecret = secret) {
  return buildApp({
    tokens: new TokenService(tokenSecret),
    challenges: new ChallengeStore(),
    appAttest: new AppAttestVerifier({
      teamId: 'U74C75726B',
      bundleId: 'de.freegroup.candle',
      environments: ['development'],
      rootCertificatePem: device.rootPem,
      now: () => validDate,
    }),
    playIntegrity: new PlayIntegrityVerifier({
      packageName: 'de.freegroup.candle',
      acceptUnrecognizedApp: false,
      decode: async () => integrityVerdicts.shift() ?? {},
    }),
    debugAttestationToken: 'debug-secret',
  });
}

async function challenge(): Promise<string> {
  const response = await app.inject({ method: 'POST', url: '/v1/auth/challenge' });
  return response.json().challenge;
}

function androidVerdict(challengeValue: string): IntegrityPayload {
  return {
    requestDetails: {
      requestPackageName: 'de.freegroup.candle',
      requestHash: challengeHash(challengeValue).toString('hex'),
      timestampMillis: String(Date.now()),
    },
    appIntegrity: { appRecognitionVerdict: 'PLAY_RECOGNIZED' },
    deviceIntegrity: { deviceRecognitionVerdict: ['MEETS_DEVICE_INTEGRITY'] },
  };
}

const post = (url: string, payload: object) => app.inject({ method: 'POST', url, payload });
const me = (accessToken: string) =>
  app.inject({ method: 'GET', url: '/v1/me', headers: { authorization: `Bearer ${accessToken}` } });

beforeEach(async () => {
  integrityVerdicts = [];
  app = await buildTestApp();
});
afterEach(() => app.close());

describe('iOS', () => {
  it('registers with an attestation and refreshes with an assertion', async () => {
    const c1 = await challenge();
    const attestation = await device.attestation(challengeHash(c1));
    const registered = await post('/v1/auth/register', {
      platform: 'ios', challenge: c1, keyId: device.keyId, attestation: attestation.toString('base64'),
    });
    expect(registered.statusCode).toBe(201);
    const { installationId, accessToken, refreshToken } = registered.json();
    expect((await me(accessToken)).json()).toEqual({ installationId });

    const c2 = await challenge();
    const refreshed = await post('/v1/auth/refresh', {
      refreshToken, challenge: c2, assertion: device.assertion(challengeHash(c2)).toString('base64'),
    });
    expect(refreshed.statusCode).toBe(200);
    expect(refreshed.json().installationId).toBe(installationId);
  });

  it('refuses a refresh without a fresh assertion', async () => {
    const c1 = await challenge();
    const attestation = await device.attestation(challengeHash(c1));
    const { refreshToken } = (
      await post('/v1/auth/register', { platform: 'ios', challenge: c1, keyId: device.keyId, attestation: attestation.toString('base64') })
    ).json();

    const c2 = await challenge();
    const replayed = device.assertion(challengeHash('an old challenge')).toString('base64');
    expect((await post('/v1/auth/refresh', { refreshToken, challenge: c2, assertion: replayed })).statusCode).toBe(401);
  });
});

describe('Android', () => {
  it('registers and refreshes with Play Integrity tokens', async () => {
    const c1 = await challenge();
    integrityVerdicts.push(androidVerdict(c1));
    const registered = await post('/v1/auth/register', { platform: 'android', challenge: c1, integrityToken: 't1' });
    expect(registered.statusCode).toBe(201);

    const c2 = await challenge();
    integrityVerdicts.push(androidVerdict(c2));
    const refreshed = await post('/v1/auth/refresh', {
      refreshToken: registered.json().refreshToken, challenge: c2, integrityToken: 't2',
    });
    expect(refreshed.statusCode).toBe(200);
    expect(refreshed.json().installationId).toBe(registered.json().installationId);
  });

  it('rejects a verdict for another challenge', async () => {
    const c1 = await challenge();
    integrityVerdicts.push(androidVerdict('another challenge'));
    expect((await post('/v1/auth/register', { platform: 'android', challenge: c1, integrityToken: 't' })).statusCode).toBe(401);
  });
});

describe('challenges', () => {
  it('can be used only once', async () => {
    const c = await challenge();
    expect((await post('/v1/auth/register', { platform: 'debug', challenge: c, debugToken: 'debug-secret' })).statusCode).toBe(201);
    expect((await post('/v1/auth/register', { platform: 'debug', challenge: c, debugToken: 'debug-secret' })).statusCode).toBe(401);
  });

  it('must have been issued by the server', async () => {
    const response = await post('/v1/auth/register', { platform: 'debug', challenge: 'made-up', debugToken: 'debug-secret' });
    expect(response.statusCode).toBe(401);
  });
});

describe('debug attestation', () => {
  it('rejects a wrong debug token', async () => {
    const response = await post('/v1/auth/register', { platform: 'debug', challenge: await challenge(), debugToken: 'guess' });
    expect(response.statusCode).toBe(401);
  });
});

describe('access', () => {
  it('requires a valid access token', async () => {
    expect((await app.inject({ method: 'GET', url: '/v1/me' })).statusCode).toBe(401);
    expect((await me('not-a-token')).statusCode).toBe(401);
  });

  it('does not accept a refresh token as access token', async () => {
    const { refreshToken } = (
      await post('/v1/auth/register', { platform: 'debug', challenge: await challenge(), debugToken: 'debug-secret' })
    ).json();
    expect((await me(refreshToken)).statusCode).toBe(401);
  });

  it('after a server rebuild with a new secret the app gets 401 and re-registers', async () => {
    const { accessToken, refreshToken } = (
      await post('/v1/auth/register', { platform: 'debug', challenge: await challenge(), debugToken: 'debug-secret' })
    ).json();

    await app.close();
    app = await buildTestApp(new TextEncoder().encode('a-completely-new-secret-after-reinstall'));

    expect((await me(accessToken)).statusCode).toBe(401);
    const refreshed = await post('/v1/auth/refresh', { refreshToken, challenge: await challenge(), debugToken: 'debug-secret' });
    expect(refreshed.statusCode).toBe(401);
    const again = await post('/v1/auth/register', { platform: 'debug', challenge: await challenge(), debugToken: 'debug-secret' });
    expect(again.statusCode).toBe(201);
  });

  it('rejects an invalid body with 400', async () => {
    expect((await post('/v1/auth/register', { platform: 'windows', challenge: 'x' })).statusCode).toBe(400);
  });

  it('answers the health check', async () => {
    expect((await app.inject({ method: 'GET', url: '/health' })).json()).toEqual({ status: 'ok' });
  });
});
