import { auth, playintegrity, type playintegrity_v1 } from '@googleapis/playintegrity';
import { AttestationError } from './errors.ts';

export type IntegrityPayload = playintegrity_v1.Schema$TokenPayloadExternal;

/** Decrypts and verifies a Play Integrity token (network call to Google). */
export type IntegrityDecoder = (token: string) => Promise<IntegrityPayload>;

export function googleIntegrityDecoder(packageName: string, serviceAccountFile: string): IntegrityDecoder {
  const client = playintegrity({
    version: 'v1',
    auth: new auth.GoogleAuth({
      keyFile: serviceAccountFile,
      scopes: ['https://www.googleapis.com/auth/playintegrity'],
    }),
  });
  return async (integrityToken) => {
    const response = await client.v1.decodeIntegrityToken({ packageName, requestBody: { integrityToken } });
    return response.data.tokenPayloadExternal ?? {};
  };
}

/**
 * Checks the verdict of a Play Integrity standard request, see
 * https://developer.android.com/google/play/integrity/verdicts
 */
export class PlayIntegrityVerifier {
  readonly #packageName: string;
  readonly #acceptUnrecognizedApp: boolean;
  readonly #debugCertificates: Buffer[];
  readonly #decode: IntegrityDecoder;
  readonly #now: () => number;

  constructor(options: {
    packageName: string;
    acceptUnrecognizedApp: boolean;
    /** SHA-256 of our debug signing certificates, hex with colons (see Config). */
    debugCertificates?: readonly string[];
    decode: IntegrityDecoder;
    now?: () => number;
  }) {
    this.#packageName = options.packageName;
    this.#acceptUnrecognizedApp = options.acceptUnrecognizedApp;
    this.#debugCertificates = (options.debugCertificates ?? []).map((hex) =>
      Buffer.from(hex.replaceAll(':', ''), 'hex'),
    );
    this.#decode = options.decode;
    this.#now = options.now ?? Date.now;
  }

  async verify(integrityToken: string, requestHash: Buffer): Promise<void> {
    let payload: IntegrityPayload;
    try {
      payload = await this.#decode(integrityToken);
    } catch (error) {
      throw new AttestationError(`Integrity token rejected by Google: ${(error as Error).message}`);
    }

    const request = payload.requestDetails;
    if (request?.requestPackageName !== this.#packageName) throw new AttestationError('Token is for another app');
    if (request.requestHash !== requestHash.toString('hex')) throw new AttestationError('Request hash does not match the challenge');
    const age = this.#now() - Number(request.timestampMillis);
    if (!(age >= -60_000 && age <= 5 * 60_000)) throw new AttestationError('Token is too old');

    const verdict = payload.appIntegrity?.appRecognitionVerdict ?? '';
    const fromGooglePlay = verdict === 'PLAY_RECOGNIZED';
    const notFromGooglePlay = verdict === 'UNRECOGNIZED_VERSION';
    const ownDebugBuild = notFromGooglePlay && this.#signedWithDebugCertificate(payload);
    const sideloadAllowed = notFromGooglePlay && this.#acceptUnrecognizedApp;
    if (!fromGooglePlay && !ownDebugBuild && !sideloadAllowed) {
      throw new AttestationError('App is not the one from Google Play');
    }
    if (!payload.deviceIntegrity?.deviceRecognitionVerdict?.includes('MEETS_DEVICE_INTEGRITY')) {
      throw new AttestationError('Device does not pass integrity checks');
    }
  }

  /** Whether Google saw the app signed with one of our debug certificates. */
  #signedWithDebugCertificate(payload: IntegrityPayload): boolean {
    // Google sends the digests base64 encoded (web-safe); Node's base64 decoder reads both alphabets
    const digests = payload.appIntegrity?.certificateSha256Digest ?? [];
    for (const digest of digests) {
      const bytes = Buffer.from(digest, 'base64');
      for (const certificate of this.#debugCertificates) {
        if (bytes.equals(certificate)) return true;
      }
    }
    return false;
  }
}
