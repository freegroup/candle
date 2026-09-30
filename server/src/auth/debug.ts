import { timingSafeEqual } from 'node:crypto';
import { AttestationError } from './errors.ts';

/** Simulators and emulators cannot attest; they use a shared secret instead (never set in production). */
export function verifyDebugToken(expected: string | undefined, actual: string | undefined): void {
  const a = Buffer.from(expected ?? '');
  const b = Buffer.from(actual ?? '');
  if (!expected || a.length !== b.length || !timingSafeEqual(a, b)) {
    throw new AttestationError('Debug attestation is not allowed');
  }
}
