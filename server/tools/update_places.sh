#!/usr/bin/env bash
# Weekly update of the places data on the server (systemd: candle-places-update,
# see ansible/04_playbook_places.yaml and README.md):
#   1. download the current extract and its outline from Geofabrik,
#   2. build the places file next to the live one and rename it into place,
#   3. delete the extract again.
# When any step fails the live file stays as it is; the error is in the journal
# (journalctl -u candle-places-update).
set -euo pipefail

# Geofabrik path of the area, e.g. europe/dach or europe/germany
region="${PLACES_REGION:-europe/dach}"
data=/home/candle/data
work="$data/work"
tools="$(dirname "$(readlink -f "$0")")"
python=/home/candle/places-venv/bin/python
agent='Candle/1.4 (de.freegroup.candle; +https://github.com/freegroup/candle)'

name="$(basename "$region")"
extract="$work/$name.osm.pbf"
outline="$work/$name.poly"

mkdir -p "$work"
# the extract is big: never leave it behind, also not after an error
trap 'rm -f "$extract"' EXIT

echo "downloading $region"
curl --fail --silent --show-error --location --user-agent "$agent" \
  --output "$extract" "https://download.geofabrik.de/$region-latest.osm.pbf"
curl --fail --silent --show-error --location --user-agent "$agent" \
  --output "$outline" "https://download.geofabrik.de/$region.poly"
echo "downloaded $(du -h "$extract" | cut -f1)"

echo "building"
"$python" -u "$tools/build_pois.py" "$extract" "$outline" "$data/places.sqlite"
echo "places data updated: $(du -h "$data/places.sqlite" | cut -f1)"
