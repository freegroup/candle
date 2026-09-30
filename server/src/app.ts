import Fastify, { type FastifyServerOptions } from 'fastify';
import { type AuthDependencies, authRoutes } from './auth/routes.ts';

export async function buildApp(deps: AuthDependencies, options: FastifyServerOptions = {}) {
  const app = Fastify(options);
  app.get('/health', async () => ({ status: 'ok' }));
  await app.register(authRoutes, deps);
  return app;
}
