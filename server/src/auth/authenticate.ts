import type { FastifyReply, FastifyRequest } from 'fastify';
import type { TokenService } from './tokens.ts';

declare module 'fastify' {
  interface FastifyRequest {
    /** Set by [authenticate] for protected routes. */
    installationId?: string;
  }
}

/** preHandler for protected routes: requires a valid access token. */
export function authenticate(tokens: TokenService) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    const header = request.headers.authorization;
    const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : undefined;
    const installationId = token ? await tokens.verifyAccessToken(token) : null;
    if (!installationId) {
      return reply.code(401).send({ error: 'unauthorized', message: 'Missing or invalid access token' });
    }
    request.installationId = installationId;
  };
}
