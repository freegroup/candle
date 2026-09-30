import { beforeAll, describe, expect, it } from 'vitest';
import { AppAttestVerifier } from '../src/auth/apple.ts';
import { challengeHash } from '../src/auth/challenge_hash.ts';
import { AttestationError } from '../src/auth/errors.ts';
import { createDevice, validDate } from './app_attest_fixture.ts';

type Device = Awaited<ReturnType<typeof createDevice>>;

describe('AppAttestVerifier', () => {
  let device: Device;
  let verifier: AppAttestVerifier;
  const hash = challengeHash('challenge-1');

  beforeAll(async () => {
    device = await createDevice();
    verifier = new AppAttestVerifier({
      teamId: 'U74C75726B',
      bundleId: 'de.freegroup.candle',
      environment: 'development',
      rootCertificatePem: device.rootPem,
      now: () => validDate,
    });
  });

  it('accepts a valid attestation and returns the public key', async () => {
    const publicKey = await verifier.verifyAttestation(device.keyId, await device.attestation(hash), hash);
    expect(Buffer.from(publicKey, 'base64')).toHaveLength(91);
  });

  it.each([
    ['another challenge', async (d: Device) => d.attestation(challengeHash('other'))],
    ['a foreign nonce', async (d: Device) => d.attestation(hash, { nonce: Buffer.alloc(32) })],
    ['another app', async (d: Device) => d.attestation(hash, { appId: 'TEAM.other.app' })],
    ['the production environment', async (d: Device) =>
      d.attestation(hash, { aaguid: Buffer.concat([Buffer.from('appattest'), Buffer.alloc(7)]) })],
    ['a used key (counter > 0)', async (d: Device) => d.attestation(hash, { counter: 1 })],
    ['a credential id that is not the key id', async (d: Device) => d.attestation(hash, { keyId: Buffer.alloc(32) })],
    ['garbage', async () => Buffer.from('not cbor at all')],
  ])('rejects an attestation for %s', async (_, make) => {
    await expect(verifier.verifyAttestation(device.keyId, await make(device), hash)).rejects.toThrow(AttestationError);
  });

  it('rejects a key id that does not belong to the certified key', async () => {
    // credential id and key id agree, but neither is the hash of the certified public key
    const otherKeyId = Buffer.alloc(32, 1);
    const attestation = await device.attestation(hash, { keyId: otherKeyId });
    await expect(verifier.verifyAttestation(otherKeyId.toString('base64'), attestation, hash)).rejects.toThrow(
      'Key id does not match the certified key',
    );
  });

  it('rejects a chain that is not signed by the trusted root', async () => {
    const stranger = await createDevice();
    await expect(verifier.verifyAttestation(stranger.keyId, await stranger.attestation(hash), hash)).rejects.toThrow(
      'Certificate chain is not from Apple',
    );
  });

  it('rejects expired certificates', async () => {
    const later = new AppAttestVerifier({
      teamId: 'U74C75726B',
      bundleId: 'de.freegroup.candle',
      environment: 'development',
      rootCertificatePem: device.rootPem,
      now: () => new Date('2030-01-01'),
    });
    await expect(later.verifyAttestation(device.keyId, await device.attestation(hash), hash)).rejects.toThrow(
      AttestationError,
    );
  });

  it('uses the real Apple root certificate by default', () => {
    expect(
      () => new AppAttestVerifier({ teamId: 'T', bundleId: 'b', environment: 'production' }),
    ).not.toThrow();
  });

  describe('assertion', () => {
    let publicKey: string;
    beforeAll(async () => {
      publicKey = await verifier.verifyAttestation(device.keyId, await device.attestation(hash), hash);
    });

    it('accepts an assertion of the attested key', () => {
      const refreshHash = challengeHash('challenge-2');
      expect(() => verifier.verifyAssertion(device.assertion(refreshHash), refreshHash, publicKey)).not.toThrow();
    });

    it('rejects an assertion for another challenge', () => {
      expect(() =>
        verifier.verifyAssertion(device.assertion(challengeHash('a')), challengeHash('b'), publicKey),
      ).toThrow('Invalid assertion signature');
    });

    it('rejects an assertion for another app', () => {
      expect(() => verifier.verifyAssertion(device.assertion(hash, { appId: 'X.y' }), hash, publicKey)).toThrow(
        'Assertion is for another app',
      );
    });

    it('rejects an assertion of another key', async () => {
      const stranger = await createDevice();
      expect(() => verifier.verifyAssertion(stranger.assertion(hash), hash, publicKey)).toThrow(AttestationError);
    });
  });
});
