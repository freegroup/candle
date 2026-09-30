import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import type { AppAttestVerifier } from './apple.ts';
import { authenticate } from './authenticate.ts';
import { challengeHash } from './challenge_hash.ts';
import type { ChallengeStore } from './challenges.ts';
import { verifyDebugToken } from './debug.ts';
import { AttestationError } from './errors.ts';
import type { PlayIntegrityVerifier } from './google.ts';
import type { Installation, Platform, TokenService } from './tokens.ts';

export interface AuthDependencies {
  tokens: TokenService;
  challenges: ChallengeStore;
  appAttest: AppAttestVerifier;
  /** Missing while no Google service account is configured. */
  playIntegrity?: PlayIntegrityVerifier;
  debugAttestationToken?: string;
}

/** Device proof of one platform; fields of the other platforms are ignored. */
interface Proof {
  challenge: string;
  /** iOS register */
  keyId?: string;
  attestation?: string;
  /** iOS refresh */
  assertion?: string;
  /** Android */
  integrityToken?: string;
  /** Simulator/emulator */
  debugToken?: string;
}

interface RegisterBody extends Proof {
  platform: Platform;
}

interface RefreshBody extends Proof {
  refreshToken: string;
}

const proofProperties = {
  challenge: { type: 'string', minLength: 1 },
  keyId: { type: 'string' },
  attestation: { type: 'string' },
  assertion: { type: 'string' },
  integrityToken: { type: 'string' },
  debugToken: { type: 'string' },
};

/**
 * Anonymous installation identity. Every install proves with App Attest (iOS)
 * or Play Integrity (Android) that it is the genuine app on a real device and
 * gets short-lived access tokens; see README for the flow.
 */
export async function authRoutes(app: FastifyInstance, deps: AuthDependencies): Promise<void> {
  const { tokens, challenges } = deps;

  app.setErrorHandler((error, request, reply) => {
    if (error instanceof AttestationError) {
      request.log.warn({ reason: error.message }, 'device proof rejected');
      return reply.code(401).send({ error: 'unauthorized', message: error.message });
    }
    return reply.send(error);
  });

  app.post('/v1/auth/challenge', async () => ({ challenge: challenges.issue() }));

  app.post<{ Body: RegisterBody }>(
    '/v1/auth/register',
    {
      schema: {
        body: {
          type: 'object',
          required: ['platform', 'challenge'],
          properties: { platform: { enum: ['ios', 'android', 'debug'] }, ...proofProperties },
        },
      },
    },
    async (request, reply) => {
      const { platform, ...proof } = request.body;
      const hash = consumeChallenge(proof.challenge);
      const installation: Installation = { id: randomUUID(), platform };

      switch (platform) {
        case 'ios':
          if (!proof.keyId || !proof.attestation) throw new AttestationError('keyId and attestation are required');
          installation.keyId = proof.keyId;
          installation.publicKey = await deps.appAttest.verifyAttestation(
            proof.keyId,
            Buffer.from(proof.attestation, 'base64'),
            hash,
          );
          break;
        case 'android':
          await verifyPlayIntegrity(proof, hash);
          break;
        case 'debug':
          verifyDebugToken(deps.debugAttestationToken, proof.debugToken);
          break;
      }

      request.log.info({ installationId: installation.id, platform }, 'installation registered');
      return reply.code(201).send(await issueTokens(installation));
    },
  );

  app.post<{ Body: RefreshBody }>(
    '/v1/auth/refresh',
    {
      schema: {
        body: {
          type: 'object',
          required: ['refreshToken', 'challenge'],
          properties: { refreshToken: { type: 'string' }, ...proofProperties },
        },
      },
    },
    async (request) => {
      const { refreshToken, ...proof } = request.body;
      const installation = await tokens.verifyRefreshToken(refreshToken);
      if (!installation) throw new AttestationError('Invalid or expired refresh token');
      const hash = consumeChallenge(proof.challenge);

      switch (installation.platform) {
        case 'ios':
          if (!proof.assertion || !installation.publicKey) throw new AttestationError('assertion is required');
          deps.appAttest.verifyAssertion(Buffer.from(proof.assertion, 'base64'), hash, installation.publicKey);
          break;
        case 'android':
          await verifyPlayIntegrity(proof, hash);
          break;
        case 'debug':
          verifyDebugToken(deps.debugAttestationToken, proof.debugToken);
          break;
      }
      return issueTokens(installation);
    },
  );

  app.get('/v1/me', { preHandler: authenticate(tokens) }, async (request) => ({
    installationId: request.installationId,
  }));

  function consumeChallenge(challenge: string): Buffer {
    if (!challenges.consume(challenge)) throw new AttestationError('Unknown or expired challenge');
    return challengeHash(challenge);
  }

  async function verifyPlayIntegrity(proof: Proof, hash: Buffer): Promise<void> {
    if (!deps.playIntegrity) throw new AttestationError('Play Integrity is not configured on this server');
    if (!proof.integrityToken) throw new AttestationError('integrityToken is required');
    await deps.playIntegrity.verify(proof.integrityToken, hash);
  }

  async function issueTokens(installation: Installation) {
    return {
      installationId: installation.id,
      accessToken: await tokens.accessToken(installation),
      refreshToken: await tokens.refreshToken(installation),
      expiresIn: tokens.accessTtlSeconds,
    };
  }
}
