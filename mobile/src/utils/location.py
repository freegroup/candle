import random
import time
import requests
import json
from threading import Thread, Lock
from geopy.geocoders import Nominatim
from geopy.distance import geodesic

from plyer import gps

class LocationManager:
    _running = False
    _thread = None
    _location = None
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
            cls._thread = Thread(target=cls._simulate_location)
            cls._thread.start()
            print("Simulate GPS Coordinates")


    @classmethod
    def stop(cls):
        """Stops the GPS tracking."""
        cls._running = False
        if cls._thread:
            cls._thread.join()
        else:
            gps.stop()


    @staticmethod
    def _simulate_location():
        while LocationManager._running:
            # Simulate GPS coordinates (latitude, longitude)
            with LocationManager._location_lock:
                LocationManager._location = (random.uniform(-90, 90), random.uniform(-180, 180))
                LocationManager._location = (49.45981391590654, 8.603280728748059)
            time.sleep(5)


    @staticmethod
    def on_gps_location(**kwargs):
        """Callback for when a new GPS location is received."""
        print("GPS location")
        latitude = kwargs.get('lat', 0.0)
        longitude = kwargs.get('lon', 0.0)
        with LocationManager._location_lock:
            LocationManager._location = (latitude, longitude)


    @staticmethod
    def on_gps_status(stype, status):
        """Callback for when GPS status changes."""
        print(f'GPS status: {stype} {status}')


    @classmethod
    def get_location(cls):
        with cls._location_lock:
            return cls._location


    def get_human_short_address(location):
        (lat, lon ) = location
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

        lat = LocationManager._location[0]
        lon = LocationManager._location[1]

        # Geocoding der Adresse, beschränkt auf die Nähe des Ausgangspunkts
        location = geolocator.geocode(address_query, viewbox=[(lat - 0.05, lon - 0.05),  (lat + 0.05, lon + 0.05)],   bounded=False)

        if location:
            print(f"Adresse: {location.address}")
            print(f"GPS-Koordinaten: {location.latitude}, {location.longitude}")
        else:
            print("Adresse konnte nicht geocodiert werden")
