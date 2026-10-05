import { statSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import type { PlacesQuery } from './query.ts';

/** A node in the Overpass JSON format the app reads. */
export interface OverpassNode {
  type: 'node';
  id: number;
  lat: number;
  lon: number;
  tags: Record<string, string>;
}

/** The places of a query, or why this server cannot answer it. */
export type PlacesAnswer = { elements: OverpassNode[] } | { unavailable: string };

interface Ring {
  hole: boolean;
  /** [lat, lon] */
  points: [number, number][];
}

/**
 * Reads the places file built by tools/build_pois.py. The file describes itself:
 * which Overpass filters it can answer and which area it covers. So this class
 * needs no knowledge of regions; a file for another area works the same.
 *
 * A new file (renamed into place by the weekly build) is picked up by the next
 * query.
 */
export class PlacesDatabase {
  readonly #path: string;
  #database: DatabaseSync | null = null;
  #openedVersion = '';
  #filters = new Set<string>();
  #rings: Ring[] = [];

  constructor(path: string) {
    this.#path = path;
  }

  answer(query: PlacesQuery): PlacesAnswer {
    const database = this.#open();
    if (database === null) return { unavailable: 'no places data on this server' };

    for (const filter of query.filters) {
      if (!this.#filters.has(filter)) return { unavailable: `filter not in the places data: ${filter}` };
    }
    if (!this.#covers(query.lat, query.lon)) return { unavailable: 'position outside the covered area' };

    // first the cheap box of the spatial index, then the exact circle
    const latDelta = query.radius / 111_320;
    const lonDelta = query.radius / (111_320 * Math.cos((query.lat * Math.PI) / 180));
    const marks = query.filters.map(() => '?').join(',');
    const rows = database
      .prepare(
        `SELECT DISTINCT places.id, places.lat, places.lon, places.tags
         FROM places_index
         JOIN places ON places.id = places_index.id
         JOIN place_filters ON place_filters.place_id = places.id
         WHERE places_index.min_lat >= ? AND places_index.max_lat <= ?
           AND places_index.min_lon >= ? AND places_index.max_lon <= ?
           AND place_filters.filter IN (${marks})`,
      )
      .all(
        query.lat - latDelta,
        query.lat + latDelta,
        query.lon - lonDelta,
        query.lon + lonDelta,
        ...query.filters,
      );

    const elements: OverpassNode[] = [];
    for (const row of rows) {
      const lat = row.lat as number;
      const lon = row.lon as number;
      if (distanceInMeters(query.lat, query.lon, lat, lon) > query.radius) continue;
      elements.push({
        type: 'node',
        id: row.id as number,
        lat,
        lon,
        tags: JSON.parse(row.tags as string) as Record<string, string>,
      });
    }
    return { elements };
  }

  /** The open database, reopened when the file was replaced; null without a file. */
  #open(): DatabaseSync | null {
    let version: string;
    try {
      const stat = statSync(this.#path);
      version = `${stat.ino}-${stat.mtimeMs}`;
    } catch {
      return null;
    }
    if (this.#database !== null && version === this.#openedVersion) return this.#database;

    this.#database?.close();
    const database = new DatabaseSync(this.#path, { readOnly: true });
    this.#filters = new Set(
      database.prepare('SELECT filter FROM filters').all().map((row) => row.filter as string),
    );
    this.#rings = [];
    for (const row of database.prepare('SELECT rings FROM coverage').all()) {
      this.#rings.push(...(JSON.parse(row.rings as string) as Ring[]));
    }
    this.#database = database;
    this.#openedVersion = version;
    return database;
  }

  /** Inside an outer ring of the covered area and not inside one of its holes. */
  #covers(lat: number, lon: number): boolean {
    let insideOuter = false;
    for (const ring of this.#rings) {
      if (!isInsideRing(lat, lon, ring.points)) continue;
      if (ring.hole) return false;
      insideOuter = true;
    }
    return insideOuter;
  }

  close(): void {
    this.#database?.close();
    this.#database = null;
  }
}

/** Ray casting; latitude and longitude act as plane coordinates, fine for an area outline. */
function isInsideRing(lat: number, lon: number, points: [number, number][]): boolean {
  let inside = false;
  for (let i = 0, j = points.length - 1; i < points.length; j = i++) {
    const [latA, lonA] = points[i];
    const [latB, lonB] = points[j];
    if (latA > lat !== latB > lat && lon < ((lonB - lonA) * (lat - latA)) / (latB - latA) + lonA) {
      inside = !inside;
    }
  }
  return inside;
}

function distanceInMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const earthRadius = 6_371_000;
  const toRadians = (degrees: number) => (degrees * Math.PI) / 180;
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * earthRadius * Math.asin(Math.sqrt(a));
}
