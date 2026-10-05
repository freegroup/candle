import Fastify, { type FastifyServerOptions } from 'fastify';
import { type AuthDependencies, authRoutes } from './auth/routes.ts';
import type { PlacesDatabase } from './places/places_database.ts';
import { placesRoutes } from './places/routes.ts';

export interface AppDependencies extends AuthDependencies {
  /** Missing on a server without places data. */
  places?: PlacesDatabase;
}

export async function buildApp(deps: AppDependencies, options: FastifyServerOptions = {}) {
  const app = Fastify(options);
  app.get('/health', async () => ({ status: 'ok' }));
  await app.register(authRoutes, deps);
  await app.register(placesRoutes, { tokens: deps.tokens, places: deps.places });
  return app;
}
