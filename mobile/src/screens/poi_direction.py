import os

from kivy.lang import Builder
from kivy.clock import Clock
from kivy.app import App

from screens.base_screen import BaseScreen
from kivy.properties import NumericProperty
from utils.tts import say


from utils.i18n import _
from utils.compass import CompassManager
from utils.location import LocationManager
from utils.gps_utils import calculate_north_bearing

dir_path = os.path.dirname(os.path.realpath(__file__))
kv_file_path = os.path.join(dir_path, 'poi_direction.kv')
image_path = os.path.join(dir_path, 'poi_direction.png') 
Builder.load_file(kv_file_path)


class PoiDirection(BaseScreen):
    needle_angle = NumericProperty(0)  # Add this line
    poi = None
    vibration_schedule = None
    distance_announced = False

    def back(self):
        App.get_running_app().navigate_to_poi_details(self.poi, "right")


    def on_enter(self):
        self.ids.arrow.source = image_path  # Set the full path to the image 
        Clock.schedule_interval(self.update_compass, 1 / 20)
        self.vibration_schedule = Clock.schedule_interval(self.vibrate_continuously, 2)


    def on_leave(self):
        Clock.unschedule(self.update_compass)
        Clock.unschedule(self.vibration_schedule)


    def update_compass(self, dt):
        poi_heading = calculate_north_bearing(LocationManager.get_location, self.poi)
        device_heading = CompassManager.get_angle()

        self.needle_angle = (poi_heading - device_heading ) % 360

        angle_abs = abs(self.needle_angle)
        if angle_abs <= 10 and not self.distance_announced:
            self.say_distance()
            self.distance_announced = True
        elif angle_abs > 30:
            self.distance_announced = False


    def say_distance(self):
        distance = self.poi.calculate_distance(LocationManager.get_location())
        say(_("Die Entfernung beträgt {} Meter").format(distance))


    def say_angle(self):
        poi_heading = calculate_north_bearing(LocationManager.get_location, self.poi)
        device_heading = CompassManager.get_angle()
        angle = (device_heading - poi_heading) % 360
        say(_("Der Winkel zum Zielort beträgt {} Grad").format(angle))


    def vibrate_continuously(self, dt):
        angle_difference = abs(self.needle_angle)
        vibration_duration = max(0.2, 2 - 2*(angle_difference / 180))  # Längere Vibration bei größerem Winkel

        self.vibrate(vibration_duration)

