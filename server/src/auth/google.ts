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
  readonly #decode: IntegrityDecoder;
  readonly #now: () => number;

  constructor(options: {
    packageName: string;
    acceptUnrecognizedApp: boolean;
    decode: IntegrityDecoder;
    now?: () => number;
  }) {
    this.#packageName = options.packageName;
    this.#acceptUnrecognizedApp = options.acceptUnrecognizedApp;
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

    const allowed = this.#acceptUnrecognizedApp ? ['PLAY_RECOGNIZED', 'UNRECOGNIZED_VERSION'] : ['PLAY_RECOGNIZED'];
    if (!allowed.includes(payload.appIntegrity?.appRecognitionVerdict ?? '')) {
      throw new AttestationError('App is not the one from Google Play');
    }
    if (!payload.deviceIntegrity?.deviceRecognitionVerdict?.includes('MEETS_DEVICE_INTEGRITY')) {
      throw new AttestationError('Device does not pass integrity checks');
    }
  }
}
