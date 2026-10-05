import type { FastifyInstance } from 'fastify';
import { authenticate } from '../auth/authenticate.ts';
import type { TokenService } from '../auth/tokens.ts';
import type { PlacesDatabase } from './places_database.ts';
import { parseQuery } from './query.ts';

export interface PlacesDependencies {
  tokens: TokenService;
  /** Missing on a server without places data: every query then gets 503. */
  places?: PlacesDatabase;
}

/**
 * POST /v1/overpass: answers the place queries of the Candle app like an Overpass
 * server (field "data" as form or JSON, the same JSON answer), for registered
 * installations only.
 *
 * What it cannot answer gets 503, never an empty list: a query for an area or a
 * filter outside its data, or another kind of query. The app then asks a public
 * Overpass server. An empty list would mean "no places here" instead.
 */
export async function placesRoutes(app: FastifyInstance, deps: PlacesDependencies) {
  // Overpass clients post a form; this route takes it as well as JSON
  app.addContentTypeParser('application/x-www-form-urlencoded', { parseAs: 'string' }, (_, body, done) => {
    done(null, Object.fromEntries(new URLSearchParams(body as string)));
  });

  app.post('/v1/overpass', { preHandler: authenticate(deps.tokens) }, async (request, reply) => {
    const data = (request.body as { data?: unknown } | undefined)?.data;
    if (typeof data !== 'string') {
      return reply.code(400).send({ error: 'bad_request', message: 'The Overpass query is missing in "data"' });
    }

    const query = parseQuery(data);
    if (query === null) {
      return reply.code(503).send({ error: 'unavailable', message: 'This kind of query is not answered here' });
    }
    if (deps.places === undefined) {
      return reply.code(503).send({ error: 'unavailable', message: 'No places data on this server' });
    }

    const answer = deps.places.answer(query);
    if ('unavailable' in answer) {
      request.log.info({ reason: answer.unavailable }, 'places query not answered');
      return reply.code(503).send({ error: 'unavailable', message: answer.unavailable });
    }
    return { version: 0.6, generator: 'Candle', elements: answer.elements };
  });
}
