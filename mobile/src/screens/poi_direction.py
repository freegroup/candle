import os
import math

from kivy.lang import Builder
from kivy.clock import Clock
from kivy.app import App

from geopy.distance import geodesic

from screens.base_screen import BaseScreen
from kivy.properties import NumericProperty
from utils.storage import Storage
from utils.tts import say


from utils.i18n import _
from utils.compass import CompassManager
from utils.location import LocationManager

dir_path = os.path.dirname(os.path.realpath(__file__))
kv_file_path = os.path.join(dir_path, 'poi_direction.kv')
image_path = os.path.join(dir_path, 'poi_direction.png') 
Builder.load_file(kv_file_path)


class PoiDirection(BaseScreen):
    needle_angle = NumericProperty(0)  # Add this line
    poi = None
    vibration_schedule = None

    def back(self):
        App.get_running_app().navigate_to_poi_details(self.poi, "right")

    def on_enter(self):
        self.ids.arrow.source = image_path  # Set the full path to the image 
        Clock.schedule_interval(self.update_compass, 1 / 20)
        self.vibration_schedule = Clock.schedule_interval(self.vibrate_continuously, 1)


    def on_leave(self):
        Clock.unschedule(self.update_compass)
        Clock.unschedule(self.vibration_schedule)


    def update_compass(self, dt):
        bearing_to_poi = self._calculate_bearing()
        current_heading = CompassManager.get_angle()

        # Berechnen des Winkels für die Nadel
        self.needle_angle = (current_heading -bearing_to_poi ) % 360

    def vibrate_continuously(self, dt):
        angle_difference = abs(self.needle_angle)
        vibration_duration = max(0.2, 1 - angle_difference / 180)  # Längere Vibration bei größerem Winkel
        pause_duration = max(0.5, angle_difference / 36) # Längere Pause bei größerem Winkel

        # Vibration starten
        print(vibration_duration)
        print(pause_duration)
        print("-------")
        self.vibrate(vibration_duration)


    def _calculate_bearing(self):
        # Aktuelle Position
        lat1, lon1 = LocationManager.get_location()

        # Zielort
        lat2, lon2 = self.poi.lat, self.poi.lon

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
        return bearing
