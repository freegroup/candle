import os
from kivy.app import App
from screens.base_screen import BaseScreen
from kivy.lang import Builder
from utils.i18n import _
from utils.tts import say
from utils.poi import Poi, PoiManager
from utils.location import LocationManager

dir_path = os.path.dirname(os.path.realpath(__file__))

kv_file_path = os.path.join(dir_path, 'navigation.kv')

Builder.load_file(kv_file_path)

class Navigation(BaseScreen):

    def back(self):
        App.get_running_app().navigate_to_main("right")

    def save_location(self):
        loc = LocationManager.get_location()
        address = LocationManager.get_human_short_address(loc)
        say(address)
        poi = Poi(lat=loc[0], lon=loc[1], name=address, desc=None)        
        PoiManager.add(poi)
