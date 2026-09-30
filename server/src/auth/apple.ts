// required by @peculiar/x509, must be loaded before it
import 'reflect-metadata';
import { createHash, verify as verifySignature } from 'node:crypto';
import { readFileSync } from 'node:fs';
import * as x509 from '@peculiar/x509';
import { decode } from 'cbor-x';
import { AttestationError } from './errors.ts';

x509.cryptoProvider.set(globalThis.crypto);

// Apple's public root certificate, valid until 2045:
// https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem
const appleRootPem = readFileSync(new URL('../../assets/apple-app-attest-root-ca.pem', import.meta.url), 'utf8');

const nonceExtensionOid = '1.2.840.113635.100.8.2';
// DER prefix of the nonce extension: SEQUENCE { [1] { OCTET STRING (32 bytes) } }
const nonceExtensionPrefix = Buffer.from([0x30, 0x24, 0xa1, 0x22, 0x04, 0x20]);
const aaguids = {
  development: Buffer.from('appattestdevelop'),
  production: Buffer.concat([Buffer.from('appattest'), Buffer.alloc(7)]),
};

interface AuthenticatorData {
  rpIdHash: Buffer;
  counter: number;
  aaguid?: Buffer;
  credentialId?: Buffer;
}

/**
 * Verifies App Attest attestations and assertions, following
 * https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server
 *
 * The assertion counter is not tracked (no database): replays are prevented by
 * the one-time challenge, and the key never leaves the Secure Enclave.
 */
export class AppAttestVerifier {
  readonly #appIdHash: Buffer;
  readonly #aaguid: Buffer;
  readonly #root: x509.X509Certificate;
  readonly #now: () => Date;

  constructor(options: {
    teamId: string;
    bundleId: string;
    environment: 'development' | 'production';
    rootCertificatePem?: string;
    now?: () => Date;
  }) {
    this.#appIdHash = sha256(Buffer.from(`${options.teamId}.${options.bundleId}`));
    this.#aaguid = aaguids[options.environment];
    this.#root = new x509.X509Certificate(options.rootCertificatePem ?? appleRootPem);
    this.#now = options.now ?? (() => new Date());
  }

  /** Checks a new key's attestation; returns its public key (SPKI DER, base64). */
  async verifyAttestation(keyId: string, attestation: Buffer, clientDataHash: Buffer): Promise<string> {
    const { fmt, attStmt, authData } = decodeMap(attestation);
    if (fmt !== 'apple-appattest' || !isBytes(authData) || !Array.isArray(attStmt?.x5c)) {
      throw new AttestationError('Malformed attestation');
    }
    const [credentialCert, intermediateCert] = (attStmt.x5c as Uint8Array[]).map(
      (der) => new x509.X509Certificate(new Uint8Array(der)),
    );
    if (!credentialCert || !intermediateCert) throw new AttestationError('Incomplete certificate chain');
    await this.#verifyChain(credentialCert, intermediateCert);

    const nonce = sha256(Buffer.concat([authData, clientDataHash]));
    const extension = credentialCert.getExtension(nonceExtensionOid);
    const extensionValue = extension ? Buffer.from(extension.value) : Buffer.alloc(0);
    if (!extensionValue.subarray(0, 6).equals(nonceExtensionPrefix) || !extensionValue.subarray(6).equals(nonce)) {
      throw new AttestationError('Nonce does not match the challenge');
    }

    const publicKey = Buffer.from(credentialCert.publicKey.rawData);
    // P-256 SPKI: 26 bytes header + 65 bytes uncompressed point
    const point = publicKey.subarray(publicKey.length - 65);
    const keyIdBytes = Buffer.from(keyId, 'base64');
    if (publicKey.length !== 91 || point[0] !== 0x04 || !sha256(point).equals(keyIdBytes)) {
      throw new AttestationError('Key id does not match the certified key');
    }

    const data = parseAuthenticatorData(authData, true);
    if (!data.rpIdHash.equals(this.#appIdHash)) throw new AttestationError('Attestation is for another app');
    if (data.counter !== 0) throw new AttestationError('Counter of a new key must be 0');
    if (!data.aaguid?.equals(this.#aaguid)) throw new AttestationError('Wrong App Attest environment');
    if (!data.credentialId?.equals(keyIdBytes)) throw new AttestationError('Credential id does not match key id');

    return publicKey.toString('base64');
  }

  /** Checks an assertion made with a previously attested key. */
  verifyAssertion(assertion: Buffer, clientDataHash: Buffer, publicKey: string): void {
    const { signature, authenticatorData } = decodeMap(assertion);
    if (!isBytes(signature) || !isBytes(authenticatorData)) throw new AttestationError('Malformed assertion');

    const nonce = sha256(Buffer.concat([authenticatorData, clientDataHash]));
    const key = { key: Buffer.from(publicKey, 'base64'), format: 'der', type: 'spki' } as const;
    if (!verifySignature('sha256', nonce, key, signature)) throw new AttestationError('Invalid assertion signature');

    const data = parseAuthenticatorData(authenticatorData, false);
    if (!data.rpIdHash.equals(this.#appIdHash)) throw new AttestationError('Assertion is for another app');
  }

  async #verifyChain(credential: x509.X509Certificate, intermediate: x509.X509Certificate): Promise<void> {
    const date = this.#now();
    const valid =
      (await credential.verify({ publicKey: intermediate, date })) &&
      (await intermediate.verify({ publicKey: this.#root, date })) &&
      (await this.#root.verify({ date }));
    if (!valid) throw new AttestationError('Certificate chain is not from Apple');
  }
}

function parseAuthenticatorData(data: Buffer, withCredential: boolean): AuthenticatorData {
  if (data.length < 37) throw new AttestationError('Authenticator data too short');
  const result: AuthenticatorData = { rpIdHash: data.subarray(0, 32), counter: data.readUInt32BE(33) };
  if (withCredential) {
    if (data.length < 55) throw new AttestationError('Authenticator data without credential');
    const length = data.readUInt16BE(53);
    result.aaguid = data.subarray(37, 53);
    result.credentialId = data.subarray(55, 55 + length);
  }
  return result;
}

function decodeMap(bytes: Buffer): Record<string, any> {
  try {
    const value = decode(bytes);
    if (value && typeof value === 'object') return value;
  } catch {
    // fall through
  }
  throw new AttestationError('Invalid CBOR');
}

function isBytes(value: unknown): value is Buffer {
  return value instanceof Uint8Array;
}

function sha256(data: Buffer): Buffer {
  return createHash('sha256').update(data).digest();
}
