import { describe, expect, it } from 'vitest';
import { challengeHash } from '../src/auth/challenge_hash.ts';
import { type IntegrityPayload, PlayIntegrityVerifier } from '../src/auth/google.ts';

const now = 1_790_000_000_000;
const hash = challengeHash('challenge');

function payload(overrides: IntegrityPayload = {}): IntegrityPayload {
  return {
    requestDetails: { requestPackageName: 'de.freegroup.candle', requestHash: hash.toString('hex'), timestampMillis: String(now - 1000) },
    appIntegrity: { appRecognitionVerdict: 'PLAY_RECOGNIZED', packageName: 'de.freegroup.candle' },
    deviceIntegrity: { deviceRecognitionVerdict: ['MEETS_DEVICE_INTEGRITY'] },
    ...overrides,
  };
}

function verifier(result: IntegrityPayload | Error, acceptUnrecognizedApp = false) {
  return new PlayIntegrityVerifier({
    packageName: 'de.freegroup.candle',
    acceptUnrecognizedApp,
    decode: async () => {
      if (result instanceof Error) throw result;
      return result;
    },
    now: () => now,
  });
}

describe('PlayIntegrityVerifier', () => {
  it('accepts a genuine app on a genuine device', async () => {
    await expect(verifier(payload()).verify('token', hash)).resolves.toBeUndefined();
  });

  it.each<[string, IntegrityPayload]>([
    ['another app', { requestDetails: { ...payload().requestDetails, requestPackageName: 'evil.app' } }],
    ['another challenge', { requestDetails: { ...payload().requestDetails, requestHash: 'abc' } }],
    ['an old token', { requestDetails: { ...payload().requestDetails, timestampMillis: String(now - 10 * 60_000) } }],
    ['a sideloaded app', { appIntegrity: { appRecognitionVerdict: 'UNRECOGNIZED_VERSION' } }],
    ['an emulator/rooted device', { deviceIntegrity: { deviceRecognitionVerdict: [] } }],
    ['an empty verdict', {}],
  ])('rejects %s', async (_, overrides) => {
    const result = Object.keys(overrides).length ? payload(overrides) : {};
    await expect(verifier(result).verify('token', hash)).rejects.toThrow();
  });

  it('accepts sideloaded test builds only when configured', async () => {
    const sideloaded = payload({ appIntegrity: { appRecognitionVerdict: 'UNRECOGNIZED_VERSION' } });
    await expect(verifier(sideloaded, true).verify('token', hash)).resolves.toBeUndefined();
  });

  it('turns Google errors into a rejection', async () => {
    await expect(verifier(new Error('invalid token')).verify('token', hash)).rejects.toThrow('rejected by Google');
  });
});
