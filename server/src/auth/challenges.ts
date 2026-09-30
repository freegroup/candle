import { randomBytes } from 'node:crypto';

/**
 * One-time challenges for the device proofs. Kept in memory on purpose: after
 * a restart pending challenges are gone and the app simply asks for a new one.
 */
export class ChallengeStore {
  readonly #ttlMs: number;
  readonly #now: () => number;
  readonly #expiresAt = new Map<string, number>();

  constructor({ ttlMs = 5 * 60_000, now = Date.now }: { ttlMs?: number; now?: () => number } = {}) {
    this.#ttlMs = ttlMs;
    this.#now = now;
  }

  issue(): string {
    this.#removeExpired();
    const challenge = randomBytes(32).toString('base64url');
    this.#expiresAt.set(challenge, this.#now() + this.#ttlMs);
    return challenge;
  }

  /** True once per issued, unexpired challenge. */
  consume(challenge: string): boolean {
    const expiresAt = this.#expiresAt.get(challenge);
    this.#expiresAt.delete(challenge);
    return expiresAt !== undefined && expiresAt > this.#now();
  }

  #removeExpired(): void {
    const now = this.#now();
    for (const [challenge, expiresAt] of this.#expiresAt) {
      if (expiresAt <= now) this.#expiresAt.delete(challenge);
    }
  }
}
