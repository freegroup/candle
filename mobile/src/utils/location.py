import random
import time
import requests
import math
import json
from threading import Thread, Lock
from geopy.geocoders import Nominatim
from geopy.distance import geodesic
from geopy import Point


from plyer import gps

from utils.poi import Poi

class LocationManager:
    _running = False
    _simulate_route_running = False
    _thread_loc_fallback = None
    _thread_simulation = None
    _location = Poi(lat=49.459511293925765, lon=8.603279976958548)
    _location_lock = Lock()

    @classmethod
    def is_active(cls):
        return cls._running

    @classmethod
    def start(cls):
        """Starts the GPS tracking."""
        cls._running = True

        try:
            # Initialize GPS for real location tracking
            gps.configure(on_location=cls.on_gps_location, on_status=cls.on_gps_status)
            gps.start(minTime=1000, minDistance=0)
            print("Using platform GPS")
        except NotImplementedError:
            cls._thread_loc_fallback = Thread(target=cls._simulate_location)
            cls._thread_loc_fallback.start()
            print("Simulate GPS Coordinates")


    @classmethod
    def stop(cls):
        """Stops the GPS tracking."""
        cls._running = False
        if cls._thread_loc_fallback:
            cls._thread_loc_fallback.join()
            cls._thread_loc_fallback = None
        else:
            gps.stop()

        cls.stop_simulate_route()


    @classmethod
    def start_simulate_route(cls, route):
        """Starts simulating movement along the given route."""
        cls._simulate_route_running = True
        cls._thread_simulation = Thread(target=cls._simulate_route, args=(route,))
        cls._thread_simulation.start()
        print("Simulating movement along the route")


    @classmethod
    def stop_simulate_route(cls):
        """Stop simulating movement along the given route."""
        cls._simulate_route_running = False
        if cls._thread_simulation:
            cls._thread_simulation.join()
            cls._thread_simulation = None


    @staticmethod
    def _simulate_location():
        while LocationManager._running:
            if not LocationManager._simulate_route_running:
                # Simulate GPS coordinates (latitude, longitude)
                with LocationManager._location_lock:
                    LocationManager._location = Poi(lat=random.uniform(-90, 90), lon=random.uniform(-180, 180))
                    LocationManager._location = Poi(lat=49.459511293925765, lon=8.603279976958548)
            time.sleep(5)


    @staticmethod
    def _simulate_route(route):
        walking_speed = 4  # Walking speed in meters/sec
        simulation_interval = 1  # Update interval in seconds
        current_point = route.get_random_point_near_route()
        current_coordinate_index = route.find_closest_segment(current_point)['end']['index']

        while LocationManager._simulate_route and current_coordinate_index < len(route.points) - 1:
            next_point = route.points[current_coordinate_index + 1]
            distance = geodesic((current_point.lat, current_point.lon), (next_point.lat, next_point.lon)).meters
            bearing = LocationManager.calculate_initial_bearing(current_point,next_point)
            normalized_walking_speed = walking_speed * simulation_interval

            if distance > normalized_walking_speed:
                destination = geodesic(meters=normalized_walking_speed).destination((current_point.lat, current_point.lon), bearing)
                current_point = Poi(lat=destination.latitude, lon=destination.longitude)
            else:
                current_coordinate_index += 1
                current_point = Poi(lat=next_point.lat, lon=next_point.lon)

            print(current_point)

            with LocationManager._location_lock:
                LocationManager._location = current_point
            time.sleep(simulation_interval)


    @staticmethod
    def on_gps_location(**kwargs):
        """Callback for when a new GPS location is received."""
        print("GPS location")
        latitude = kwargs.get('lat', 0.0)
        longitude = kwargs.get('lon', 0.0)
        with LocationManager._location_lock:
            LocationManager._location = Poi(lat=latitude, lon=longitude)


    @staticmethod
    def on_gps_status(stype, status):
        """Callback for when GPS status changes."""
        print(f'GPS status: {stype} {status}')


    @classmethod
    def get_location(cls):
        with cls._location_lock:
            print(f"get location {cls._location}")
            return cls._location


    def get_human_short_address(location):
        lat, lon  = location.lat, location.lon
        # Use a geocoding service to resolve the address
        url = f"https://nominatim.openstreetmap.org/reverse?format=json&lat={lat}&lon={lon}"
        response = requests.get(url)
        if response.status_code == 200:
            address_info = response.json().get('address', {})
            print(json.dumps(address_info, indent=4))
            # Extract relevant components
            house_number = address_info.get('house_number', '')
            road = address_info.get('road', '')
            city = address_info.get('city', address_info.get('town',  address_info.get('municipality', '')))
            

            # Format the address
            formatted_address = f"{road} {house_number} in {city}"
            return formatted_address.strip()
        else:
            raise Exception("openstreetmap do not response with an 200 code.")
        

    @staticmethod
    def geocode_address( address_query):
        # Erstellen eines Geocoders mit Nominatim
        geolocator = Nominatim(user_agent="candle")

        lat = LocationManager._location.lat
        lon = LocationManager._location.lon

        # Geocoding der Adresse, beschränkt auf die Nähe des Ausgangspunkts
        location = geolocator.geocode(address_query, viewbox=[(lat - 0.05, lon - 0.05),  (lat + 0.05, lon + 0.05)], bounded=True)

        if location:
            print(f"Adresse: {location.address}")
            print(f"GPS-Koordinaten: {location.latitude}, {location.longitude}")
        else:
            print("Adresse konnte nicht geocodiert werden")



    @staticmethod
    def calculate_initial_bearing(poi1, poi2):
        lat1, lon1 = math.radians(poi1.lat), math.radians(poi1.lon)
        lat2, lon2 = math.radians(poi2.lat), math.radians(poi2.lon)

        dlon = lon2 - lon1
        x = math.sin(dlon) * math.cos(lat2)
        y = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dlon)

        initial_bearing = math.atan2(x, y)
        initial_bearing = math.degrees(initial_bearing)
        bearing = (initial_bearing + 360) % 360

        return bearing
