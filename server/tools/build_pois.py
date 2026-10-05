"""Builds the places database of the Candle server from an OSM extract.

Usage:
    python build_pois.py <extract.osm.pbf> <area.poly> <out.sqlite>

<extract.osm.pbf> and <area.poly> come from Geofabrik, e.g. for DACH:
    https://download.geofabrik.de/europe/dach-latest.osm.pbf
    https://download.geofabrik.de/europe/dach.poly

The file is self-describing, so the server needs no knowledge of its own:
- places, place_filters, places_index: the nodes and which Overpass filters
  they match, with a spatial index.
- filters: the Overpass node filters this file can answer. A query with any
  other filter gets 503 from the server, and the app asks a public server.
- coverage: the outline of the area the data covers. The server answers only
  for positions inside it.

The file is written under a temporary name and renamed at the end, so a server
reading <out.sqlite> never sees half a database.
"""
import json
import os
import re
import sqlite3
import sys
import time

import osmium

# The Overpass node filters the app sends, per category, written exactly as in
# app/lib/data/repositories/poi/poi_repository_remote.dart.
FILTERS = {
    'crossings': ['["highway"="crossing"]'],
    'bars': ['["amenity"="bar"]', '["amenity"="nightclub"]'],
    'atms': ['["amenity"="atm"]', '["amenity"="bank"]'],
    'restaurants': ['["amenity"="restaurant"]'],
    'hospitals': ['["amenity"="hospital"]'],
    'cafes': ['["amenity"="cafe"]'],
    'busStations': ['["amenity"="bus_station"]', '["highway"="bus_stop"]'],
    'taxis': ['["amenity"="taxi"]'],
    'pharmacies': ['["amenity"="pharmacy"]'],
    'audibleSignals': [
        '["highway"="traffic_signals"]["traffic_signals:sound"="yes"]',
        '["crossing"="traffic_signals"]["traffic_signals:sound"="yes"]',
    ],
    'publicToilets': ['["amenity"="toilets"]'],
}

TAG_CONDITION = re.compile(r'\["([^"]+)"="([^"]+)"\]')

# every filter with its tag conditions, e.g. ('["amenity"="bar"]', [('amenity', 'bar')])
CONDITIONS = [
    (filter_text, TAG_CONDITION.findall(filter_text))
    for filters in FILTERS.values()
    for filter_text in filters
]

# a node without any of these keys matches no filter, so it is skipped cheaply
KEYS = {key for _, conditions in CONDITIONS for key, _ in conditions}

PROGRESS_EVERY = 50_000_000


def filters_of(tags):
    """The filters a node with these tags matches."""
    matching = []
    for filter_text, conditions in CONDITIONS:
        if all(tags.get(key) == value for key, value in conditions):
            matching.append(filter_text)
    return matching


def read_poly(path):
    """The area name and the rings of a Geofabrik .poly file as lists of [lat, lon].

    A ring whose header starts with '!' is a hole; it is kept with "hole": true.
    """
    with open(path, encoding='utf-8') as file:
        lines = [line.strip() for line in file]
    # Geofabrik writes "none" as the name, so the file name tells the area (e.g. "dach")
    name = os.path.splitext(os.path.basename(path))[0]
    rings = []
    index = 1
    while index < len(lines) and lines[index] != 'END':
        header = lines[index]
        index += 1
        points = []
        while lines[index] != 'END':
            lon, lat = lines[index].split()
            points.append([float(lat), float(lon)])
            index += 1
        index += 1  # the END of this ring
        rings.append({'hole': header.startswith('!'), 'points': points})
    return name, rings


class PlaceCollector(osmium.SimpleHandler):
    def __init__(self, database):
        super().__init__()
        self.database = database
        self.nodes = 0
        self.places = 0
        self.started = time.time()

    def node(self, node):
        self.nodes += 1
        if self.nodes % PROGRESS_EVERY == 0:
            minutes = (time.time() - self.started) / 60
            print(f'{self.nodes // 1_000_000} million nodes read, {self.places} places, {minutes:.0f} min',
                  flush=True)

        if not any(key in node.tags for key in KEYS):
            return
        tags = {tag.k: tag.v for tag in node.tags}
        matching = filters_of(tags)
        if not matching:
            return

        lat = node.location.lat
        lon = node.location.lon
        self.database.execute(
            'INSERT INTO places (id, lat, lon, tags) VALUES (?, ?, ?, ?)',
            (node.id, lat, lon, json.dumps(tags, ensure_ascii=False)),
        )
        # the spatial index stores boxes; for a point both corners are the same
        self.database.execute(
            'INSERT INTO places_index (id, min_lat, max_lat, min_lon, max_lon) VALUES (?, ?, ?, ?, ?)',
            (node.id, lat, lat, lon, lon),
        )
        for filter_text in matching:
            self.database.execute(
                'INSERT INTO place_filters (place_id, filter) VALUES (?, ?)', (node.id, filter_text)
            )
        self.places += 1


def main():
    extract, poly, out = sys.argv[1], sys.argv[2], sys.argv[3]
    building = out + '.building'
    if os.path.exists(building):
        os.remove(building)

    database = sqlite3.connect(building)
    database.executescript('''
        CREATE TABLE places (
            id INTEGER PRIMARY KEY,          -- the OSM node id
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            tags TEXT NOT NULL               -- all tags of the node as JSON
        );
        CREATE TABLE place_filters (
            place_id INTEGER NOT NULL,
            filter TEXT NOT NULL             -- an Overpass node filter the place matches
        );
        CREATE VIRTUAL TABLE places_index USING rtree(id, min_lat, max_lat, min_lon, max_lon);
        CREATE TABLE filters (filter TEXT PRIMARY KEY, category TEXT NOT NULL);
        CREATE TABLE coverage (name TEXT NOT NULL, rings TEXT NOT NULL, built_at TEXT NOT NULL);
    ''')

    for category, filters in FILTERS.items():
        for filter_text in filters:
            database.execute('INSERT INTO filters (filter, category) VALUES (?, ?)', (filter_text, category))

    name, rings = read_poly(poly)
    database.execute(
        'INSERT INTO coverage (name, rings, built_at) VALUES (?, ?, ?)',
        (name, json.dumps(rings), time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())),
    )

    collector = PlaceCollector(database)
    collector.apply_file(extract)
    print(f'{collector.nodes // 1_000_000} million nodes read, {collector.places} places; indexing', flush=True)
    database.execute('CREATE INDEX place_filters_by_place ON place_filters (place_id)')
    database.commit()
    database.execute('VACUUM')
    database.close()
    os.replace(building, out)
    minutes = (time.time() - collector.started) / 60
    print(f'done: {collector.places} places in {name}, {minutes:.0f} min', flush=True)


if __name__ == '__main__':
    main()
