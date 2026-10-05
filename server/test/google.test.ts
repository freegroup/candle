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

// our debug certificate as keytool prints it, and as Google reports it (base64, web-safe)
const debugCertificate =
  '5F:BF:8E:9E:D0:52:95:A0:71:D1:00:C0:CB:C5:4E:15:27:9D:E9:05:B3:18:BE:A1:9B:86:5E:89:77:6A:44:05';
const debugDigest = Buffer.from(debugCertificate.replaceAll(':', ''), 'hex').toString('base64url');
const otherDigest = Buffer.alloc(32, 7).toString('base64url');

function verifier(result: IntegrityPayload | Error, acceptUnrecognizedApp = false) {
  return new PlayIntegrityVerifier({
    packageName: 'de.freegroup.candle',
    acceptUnrecognizedApp,
    debugCertificates: [debugCertificate],
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

  it('accepts our own debug build, signed with a configured certificate', async () => {
    const debugBuild = payload({
      appIntegrity: { appRecognitionVerdict: 'UNRECOGNIZED_VERSION', certificateSha256Digest: [debugDigest] },
    });
    await expect(verifier(debugBuild).verify('token', hash)).resolves.toBeUndefined();
  });

  it('rejects a build that is not from Google Play and signed by someone else', async () => {
    const foreignBuild = payload({
      appIntegrity: { appRecognitionVerdict: 'UNRECOGNIZED_VERSION', certificateSha256Digest: [otherDigest] },
    });
    await expect(verifier(foreignBuild).verify('token', hash)).rejects.toThrow('not the one from Google Play');
  });

  it('rejects our own debug build on a device that fails the integrity checks', async () => {
    const debugBuildOnEmulator = payload({
      appIntegrity: { appRecognitionVerdict: 'UNRECOGNIZED_VERSION', certificateSha256Digest: [debugDigest] },
      deviceIntegrity: { deviceRecognitionVerdict: [] },
    });
    await expect(verifier(debugBuildOnEmulator).verify('token', hash)).rejects.toThrow('integrity checks');
  });

  it('turns Google errors into a rejection', async () => {
    await expect(verifier(new Error('invalid token')).verify('token', hash)).rejects.toThrow('rejected by Google');
  });
});
