import { jwtVerify, SignJWT } from 'jose';

export type Platform = 'ios' | 'android' | 'debug';

/** What the server knows about an installation; carried in the refresh token instead of a database. */
export interface Installation {
  id: string;
  platform: Platform;
  /** iOS: App Attest key id and public key (SPKI DER, base64) to verify assertions. */
  keyId?: string;
  publicKey?: string;
}

const issuer = 'candle-server';
const audience = 'candle-app';

/**
 * Stateless tokens: the access token proves the installation for API calls,
 * the refresh token carries the installation itself. Every refresh also needs
 * a fresh device proof, so a stolen refresh token alone is useless.
 */
export class TokenService {
  readonly #secret: Uint8Array;
  readonly accessTtlSeconds: number;
  readonly refreshTtlSeconds: number;

  constructor(
    secret: Uint8Array,
    { accessTtlSeconds = 60 * 60, refreshTtlSeconds = 90 * 24 * 60 * 60 } = {},
  ) {
    this.#secret = secret;
    this.accessTtlSeconds = accessTtlSeconds;
    this.refreshTtlSeconds = refreshTtlSeconds;
  }

  accessToken(installation: Installation): Promise<string> {
    return this.#sign({ typ: 'access', plt: installation.platform }, installation.id, this.accessTtlSeconds);
  }

  refreshToken(installation: Installation): Promise<string> {
    const { id, platform, keyId, publicKey } = installation;
    return this.#sign({ typ: 'refresh', plt: platform, kid: keyId, pub: publicKey }, id, this.refreshTtlSeconds);
  }

  /** Installation id of a valid access token, null otherwise. */
  async verifyAccessToken(token: string): Promise<string | null> {
    const payload = await this.#verify(token, 'access');
    return payload?.sub ?? null;
  }

  async verifyRefreshToken(token: string): Promise<Installation | null> {
    const payload = await this.#verify(token, 'refresh');
    if (!payload?.sub) return null;
    return {
      id: payload.sub,
      platform: payload.plt as Platform,
      keyId: payload.kid as string | undefined,
      publicKey: payload.pub as string | undefined,
    };
  }

  #sign(claims: Record<string, unknown>, subject: string, ttlSeconds: number): Promise<string> {
    return new SignJWT(claims)
      .setProtectedHeader({ alg: 'HS256' })
      .setSubject(subject)
      .setIssuer(issuer)
      .setAudience(audience)
      .setIssuedAt()
      .setExpirationTime(`${ttlSeconds}s`)
      .sign(this.#secret);
  }

  async #verify(token: string, type: 'access' | 'refresh') {
    try {
      const { payload } = await jwtVerify(token, this.#secret, {
        issuer,
        audience,
        algorithms: ['HS256'],
      });
      return payload.typ === type ? payload : null;
    } catch {
      return null;
    }
  }
}
