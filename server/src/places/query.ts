/**
 * The part of Overpass QL that the Candle app sends for places, e.g.
 *
 *   [out:json][timeout:25];
 *   (
 *   node["amenity"="bar"](around:2000,52.5163,13.3777);
 *   node["highway"="traffic_signals"]["traffic_signals:sound"="yes"](around:2000,52.5163,13.3777);
 *   );
 *   out center;
 *
 * Anything else (ways, other filters, other output) is not understood: the
 * caller then answers 503 and the app asks a public Overpass server.
 */
export interface PlacesQuery {
  /** The node filters, written exactly as in the query, e.g. ["amenity"="bar"]. */
  filters: string[];
  radius: number;
  lat: number;
  lon: number;
}

const SETTINGS = /^(\[[a-z]+:[^\]]+\])+$/;
const OUTPUT = /^out( center| body)?$/;
const NODE_AROUND = /^node((?:\["[^"]+"="[^"]+"\])+)\(around:([0-9.]+),(-?[0-9.]+),(-?[0-9.]+)\)$/;

/** The query, or null when it is not one Candle sends for places. */
export function parseQuery(text: string): PlacesQuery | null {
  // the filters contain no ";", so the statements can be split at it
  const parts = text.split(';').map((part) => part.trim()).filter((part) => part.length > 0);

  if (parts.length > 0 && SETTINGS.test(parts[0])) parts.shift();
  const output = parts.pop();
  if (output === undefined || !OUTPUT.test(output)) return null;

  // a union "( a; b; );" splits into "(a", "b", ")"
  if (parts.length > 0 && parts[0].startsWith('(')) {
    parts[0] = parts[0].slice(1).trim();
    if (parts.at(-1) !== ')') return null;
    parts.pop();
  }
  if (parts.length === 0) return null;

  const filters: string[] = [];
  let around: { radius: number; lat: number; lon: number } | null = null;
  for (const statement of parts) {
    const match = NODE_AROUND.exec(statement);
    if (match === null) return null;
    const [, filter, radius, lat, lon] = match;
    const statementAround = { radius: Number(radius), lat: Number(lat), lon: Number(lon) };
    // Candle asks for one circle per query; different circles are not expected
    if (around === null) {
      around = statementAround;
    } else if (
      around.radius !== statementAround.radius ||
      around.lat !== statementAround.lat ||
      around.lon !== statementAround.lon
    ) {
      return null;
    }
    filters.push(filter);
  }
  if (around === null) return null;
  return { filters, radius: around.radius, lat: around.lat, lon: around.lon };
}
