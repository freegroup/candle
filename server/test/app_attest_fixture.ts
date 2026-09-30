// required by @peculiar/x509, must be loaded before it
import 'reflect-metadata';
import { createHash, createPrivateKey, sign } from 'node:crypto';
import * as x509 from '@peculiar/x509';
import { encode } from 'cbor-x';

// Builds App Attest objects like a real iPhone does, but signed by a test root CA.

const algorithm = { name: 'ECDSA', namedCurve: 'P-256', hash: 'SHA-256' };
const notBefore = new Date('2026-01-01');
const notAfter = new Date('2027-01-01');
export const validDate = new Date('2026-09-30');
export const appId = 'U74C75726B.de.freegroup.candle';

const sha256 = (data: Buffer) => createHash('sha256').update(data).digest();

export interface AttestationOverrides {
  appId?: string;
  aaguid?: Buffer;
  counter?: number;
  /** Nonce in the certificate; defaults to the correct one. */
  nonce?: Buffer;
  keyId?: Buffer;
}

export async function createDevice() {
  x509.cryptoProvider.set(globalThis.crypto);
  const keys = () => crypto.subtle.generateKey(algorithm, true, ['sign', 'verify']);
  const [rootKeys, intermediateKeys, credentialKeys] = await Promise.all([keys(), keys(), keys()]);

  const root = await x509.X509CertificateGenerator.createSelfSigned({
    serialNumber: '01',
    name: 'CN=Test App Attest Root',
    notBefore,
    notAfter,
    keys: rootKeys,
    signingAlgorithm: algorithm,
    extensions: [new x509.BasicConstraintsExtension(true, undefined, true)],
  });
  const intermediate = await x509.X509CertificateGenerator.create({
    serialNumber: '02',
    subject: 'CN=Test App Attest CA',
    issuer: root.subject,
    notBefore,
    notAfter,
    publicKey: intermediateKeys.publicKey,
    signingKey: rootKeys.privateKey,
    signingAlgorithm: algorithm,
    extensions: [new x509.BasicConstraintsExtension(true, 0, true)],
  });

  const spki = Buffer.from(await crypto.subtle.exportKey('spki', credentialKeys.publicKey));
  const keyIdBytes = sha256(spki.subarray(spki.length - 65));
  const privateKey = createPrivateKey({
    key: Buffer.from(await crypto.subtle.exportKey('pkcs8', credentialKeys.privateKey)),
    format: 'der',
    type: 'pkcs8',
  });

  return {
    rootPem: root.toString('pem'),
    keyId: keyIdBytes.toString('base64'),

    async attestation(clientDataHash: Buffer, overrides: AttestationOverrides = {}): Promise<Buffer> {
      const authData = Buffer.concat([
        sha256(Buffer.from(overrides.appId ?? appId)),
        Buffer.from([0x40]),
        uint32(overrides.counter ?? 0),
        overrides.aaguid ?? Buffer.from('appattestdevelop'),
        Buffer.from([0x00, 0x20]),
        overrides.keyId ?? keyIdBytes,
      ]);
      const nonce = overrides.nonce ?? sha256(Buffer.concat([authData, clientDataHash]));
      const credential = await x509.X509CertificateGenerator.create({
        serialNumber: '03',
        subject: 'CN=credential',
        issuer: intermediate.subject,
        notBefore,
        notAfter,
        publicKey: credentialKeys.publicKey,
        signingKey: intermediateKeys.privateKey,
        signingAlgorithm: algorithm,
        extensions: [
          new x509.Extension(
            '1.2.840.113635.100.8.2',
            false,
            Buffer.concat([Buffer.from([0x30, 0x24, 0xa1, 0x22, 0x04, 0x20]), nonce]),
          ),
        ],
      });
      return Buffer.from(
        encode({
          fmt: 'apple-appattest',
          attStmt: {
            x5c: [Buffer.from(credential.rawData), Buffer.from(intermediate.rawData)],
            receipt: Buffer.alloc(0),
          },
          authData,
        }),
      );
    },

    assertion(clientDataHash: Buffer, options: { appId?: string; counter?: number } = {}): Buffer {
      const authenticatorData = Buffer.concat([
        sha256(Buffer.from(options.appId ?? appId)),
        Buffer.from([0x00]),
        uint32(options.counter ?? 1),
      ]);
      const nonce = sha256(Buffer.concat([authenticatorData, clientDataHash]));
      return Buffer.from(encode({ signature: sign('sha256', nonce, privateKey), authenticatorData }));
    },
  };
}

function uint32(value: number): Buffer {
  const buffer = Buffer.alloc(4);
  buffer.writeUInt32BE(value);
  return buffer;
}
