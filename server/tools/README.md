# Places data

`build_pois.py` builds the places file the server answers `POST /v1/overpass`
from (see `src/places/`). It keeps the OSM nodes that match the Overpass filters
the app sends and writes, into the same file, which filters it can answer and
which area it covers. The server needs no other knowledge: a file for another
area works without code changes.

## Build on the Mac

```bash
cd gis-test                                     # big files stay out of git there
python3 -m venv venv && venv/bin/pip install -r ../server/tools/requirements.txt
curl -LO https://download.geofabrik.de/europe/dach-latest.osm.pbf
curl -LO https://download.geofabrik.de/europe/dach.poly
venv/bin/python ../server/tools/build_pois.py dach-latest.osm.pbf dach.poly dach.sqlite
```

It prints its progress every 50 million nodes. Berlin takes under a minute.

## Put it on the server

```bash
ansible-playbook -i ./ansible/inventory.ini ./ansible/04_playbook_places.yaml -e places_file=gis-test/dach.sqlite
```

The file arrives next to the live one and is renamed into place; the server
uses it from the next query on.
