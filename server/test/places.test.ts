import { mkdtempSync, renameSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import type { FastifyInstance } from 'fastify';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.ts';
import { AppAttestVerifier } from '../src/auth/apple.ts';
import { ChallengeStore } from '../src/auth/challenges.ts';
import { TokenService } from '../src/auth/tokens.ts';
import { PlacesDatabase } from '../src/places/places_database.ts';
import { parseQuery } from '../src/places/query.ts';

const secret = new TextEncoder().encode('a-test-secret-with-at-least-32-characters');
const tokens = new TokenService(secret);

const bar = '["amenity"="bar"]';
const nightclub = '["amenity"="nightclub"]';
const cafe = '["amenity"="cafe"]';
const audibleSignal = '["highway"="traffic_signals"]["traffic_signals:sound"="yes"]';

/** A query as the app writes it (PoiRepositoryRemote). */
function appQuery(filters: string[], lat = 52.5163, lon = 13.3777, radius = 2000): string {
  const around = `(around:${radius},${lat},${lon})`;
  const statements = filters.map((filter) => `node${filter}${around};`).join('\n');
  return `[out:json][timeout:25];\n(\n${statements}\n);\nout center;`;
}

/** A places file in the format of tools/build_pois.py: a square around Berlin-Mitte. */
function writePlacesFile(path: string, places: { id: number; lat: number; lon: number; tags: object; filters: string[] }[]) {
  const database = new DatabaseSync(path);
  database.exec(`
    CREATE TABLE places (id INTEGER PRIMARY KEY, lat REAL NOT NULL, lon REAL NOT NULL, tags TEXT NOT NULL);
    CREATE TABLE place_filters (place_id INTEGER NOT NULL, filter TEXT NOT NULL);
    CREATE VIRTUAL TABLE places_index USING rtree(id, min_lat, max_lat, min_lon, max_lon);
    CREATE TABLE filters (filter TEXT PRIMARY KEY, category TEXT NOT NULL);
    CREATE TABLE coverage (name TEXT NOT NULL, rings TEXT NOT NULL, built_at TEXT NOT NULL);
  `);
  for (const filter of [bar, nightclub, cafe, audibleSignal]) {
    database.prepare('INSERT INTO filters VALUES (?, ?)').run(filter, 'test');
  }
  const square = [[52.4, 13.2], [52.4, 13.6], [52.6, 13.6], [52.6, 13.2], [52.4, 13.2]];
  database.prepare('INSERT INTO coverage VALUES (?, ?, ?)').run('test', JSON.stringify([{ hole: false, points: square }]), 'now');
  for (const place of places) {
    database.prepare('INSERT INTO places VALUES (?, ?, ?, ?)').run(place.id, place.lat, place.lon, JSON.stringify(place.tags));
    database.prepare('INSERT INTO places_index VALUES (?, ?, ?, ?, ?)').run(place.id, place.lat, place.lat, place.lon, place.lon);
    for (const filter of place.filters) database.prepare('INSERT INTO place_filters VALUES (?, ?)').run(place.id, filter);
  }
  database.close();
}

const places = [
  { id: 1, lat: 52.517, lon: 13.378, tags: { amenity: 'bar', name: 'Bar' }, filters: [bar] },
  { id: 2, lat: 52.518, lon: 13.379, tags: { amenity: 'nightclub', name: 'Club' }, filters: [nightclub] },
  { id: 3, lat: 52.519, lon: 13.380, tags: { amenity: 'cafe', name: 'Café' }, filters: [cafe] },
  // ~5 km away: inside the area, outside a 2 km circle
  { id: 4, lat: 52.56, lon: 13.38, tags: { amenity: 'bar', name: 'Far bar' }, filters: [bar] },
];

let directory: string;
let path: string;
let app: FastifyInstance;
let accessToken: string;

beforeEach(async () => {
  directory = mkdtempSync(join(tmpdir(), 'candle-places-'));
  path = join(directory, 'places.sqlite');
  writePlacesFile(path, places);
  app = await buildApp({
    tokens,
    challenges: new ChallengeStore(),
    appAttest: new AppAttestVerifier({ teamId: 'T', bundleId: 'b', environments: ['development'] }),
    places: new PlacesDatabase(path),
  });
  accessToken = await tokens.accessToken({ id: 'installation-1', platform: 'android' });
});

afterEach(async () => {
  await app.close();
  rmSync(directory, { recursive: true, force: true });
});

function ask(data: string, headers: Record<string, string> = { authorization: `Bearer ${accessToken}` }) {
  return app.inject({
    method: 'POST',
    url: '/v1/overpass',
    headers: { 'content-type': 'application/x-www-form-urlencoded', ...headers },
    payload: new URLSearchParams({ data }).toString(),
  });
}

describe('parseQuery', () => {
  it('reads the place query of the app', () => {
    expect(parseQuery(appQuery([bar, audibleSignal]))).toEqual({
      filters: [bar, audibleSignal],
      radius: 2000,
      lat: 52.5163,
      lon: 13.3777,
    });
  });

  it.each([
    ['the building query of the indoor check', '[out:json][timeout:4];way(around:30,52.5,13.4)[building];out geom;'],
    ['a way statement', '[out:json];(node["highway"="crossing"](around:500,52.5,13.4);way["highway"="crossing"](around:500,52.5,13.4););out center;'],
    ['circles that differ', '[out:json];(node["amenity"="bar"](around:500,52.5,13.4);node["amenity"="cafe"](around:900,52.5,13.4););out center;'],
    ['no output statement', '[out:json];node["amenity"="bar"](around:500,52.5,13.4);'],
    ['nonsense', 'hello'],
  ])('does not read %s', (_, text) => {
    expect(parseQuery(text)).toBeNull();
  });
});

describe('POST /v1/overpass', () => {
  it('rejects a call without a valid access token', async () => {
    expect((await ask(appQuery([bar]), {})).statusCode).toBe(401);
    expect((await ask(appQuery([bar]), { authorization: 'Bearer forged' })).statusCode).toBe(401);
  });

  it('answers like Overpass: the nodes of the asked filters within the circle', async () => {
    const response = await ask(appQuery([bar, cafe]));
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.elements.map((element: { id: number }) => element.id).sort()).toEqual([1, 3]);
    expect(body.elements.find((element: { id: number }) => element.id === 1)).toEqual({
      type: 'node',
      id: 1,
      lat: 52.517,
      lon: 13.378,
      tags: { amenity: 'bar', name: 'Bar' },
    });
  });

  it('gives only the asked filter, not its whole category', async () => {
    const ids = (await ask(appQuery([bar]))).json().elements.map((element: { id: number }) => element.id);
    expect(ids).toEqual([1]); // not the nightclub
  });

  it('takes the query as JSON as well', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/overpass',
      headers: { authorization: `Bearer ${accessToken}` },
      payload: { data: appQuery([cafe]) },
    });
    expect(response.json().elements.map((element: { id: number }) => element.id)).toEqual([3]);
  });

  it.each([
    ['a position outside the covered area', appQuery([bar], 48.137, 11.575)],
    ['a filter that is not in the data', appQuery(['["amenity"="school"]'])],
    ['a query of another kind', '[out:json][timeout:4];way(around:30,52.5163,13.3777)[building];out geom;'],
  ])('answers 503 for %s, so the app asks a public server', async (_, data) => {
    expect((await ask(data)).statusCode).toBe(503);
  });

  it('answers 400 when the field "data" is missing, 503 for an empty query', async () => {
    expect((await ask('')).statusCode).toBe(503);
    const response = await app.inject({
      method: 'POST',
      url: '/v1/overpass',
      headers: { authorization: `Bearer ${accessToken}` },
      payload: { other: 'x' },
    });
    expect(response.statusCode).toBe(400);
  });

  it('picks up a new places file that replaced the old one', async () => {
    expect((await ask(appQuery([bar]))).json().elements).toHaveLength(1);

    const next = join(directory, 'next.sqlite');
    writePlacesFile(next, [...places, { id: 5, lat: 52.5165, lon: 13.3779, tags: { amenity: 'bar' }, filters: [bar] }]);
    renameSync(next, path);

    expect((await ask(appQuery([bar]))).json().elements).toHaveLength(2);
  });

  it('answers 503 while the server has no places file', async () => {
    rmSync(path);
    expect((await ask(appQuery([bar]))).statusCode).toBe(503);
  });
});
