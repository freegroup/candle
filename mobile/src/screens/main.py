import os
from screens.base_screen import BaseScreen
from kivy.lang import Builder
from gps.location import LocationManager


dir_path = os.path.dirname(os.path.realpath(__file__))
kv_file_path = os.path.join(dir_path, 'main.kv')

Builder.load_file(kv_file_path)

class Main(BaseScreen):
    
    def location(self):
        try:
            location = LocationManager.get_location()
            address = LocationManager.get_human_short_address(location)
            # Use a geocoding service to resolve the address
            # For example, using OpenStreetMap's Nominatim (note: use it responsibly)
            self.tts("Sie befinden sich in: " + address)
        except Exception as e:
            print(e)
            self.tts("Ich konnte leider ihren Standort nicht ermitteln.")
