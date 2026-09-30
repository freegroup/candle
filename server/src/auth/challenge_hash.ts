import { createHash } from 'node:crypto';

/**
 * The app binds its device proof to SHA-256(challenge): App Attest takes it as
 * clientDataHash, Play Integrity as requestHash (hex).
 */
export function challengeHash(challenge: string): Buffer {
  return createHash('sha256').update(challenge, 'utf8').digest();
}
