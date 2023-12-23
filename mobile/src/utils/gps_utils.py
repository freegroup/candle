import math
from utils.poi import Poi



def calculate_north_bearing(poi_base: Poi, poi_target: Poi):
    # Aktuelle Position
    lat1, lon1 = poi_base.lat, poi_base.lon

    # Zielort
    lat2, lon2 = poi_target.lat, poi_target.lon

    # Differenz der Längengrade
    delta_lon = math.radians(lon2 - lon1)

    # Umrechnung in Radianten
    lat1, lat2 = map(math.radians, [lat1, lat2])

    # Berechnung des Azimuts
    x = math.sin(delta_lon) * math.cos(lat2)
    y = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(delta_lon)

    # Umwandlung von Radianten in Grad
    bearing = math.degrees(math.atan2(x, y))
    bearing = (bearing + 360) % 360  # Normalisierung auf 0-360 Grad
    return int(bearing)


if __name__ == "__main__":
    poi1 = Poi( name="home", lat= 49.4596733, lon= 8.6032483)
    poi2 = Poi( name="Lidl", lat= 49.45622156121109, lon= 8.596111485518252)
    print(calculate_north_bearing(poi_base=poi1, poi_target=poi2))
