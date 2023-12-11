import os
from kivy.app import App
from screens.base_screen import BaseScreen
from kivy.lang import Builder
from utils.i18n import _
from utils.tts import say
from utils.poi import Poi, PoiManager
from utils.location import LocationManager

dir_path = os.path.dirname(os.path.realpath(__file__))

kv_file_path = os.path.join(dir_path, 'poi_details.kv')

Builder.load_file(kv_file_path)

class PoiDetails(BaseScreen):
    poi = None  # Attribute to hold the passed POI

    def back(self):
        App.get_running_app().navigate_to_pois("right")

