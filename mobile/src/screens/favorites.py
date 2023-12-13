import os
from kivy.app import App
from screens.base_screen import BaseScreen
from kivy.lang import Builder
from utils.i18n import _
from utils.tts import say
from utils.poi import Poi, PoiManager
from utils.location import LocationManager

dir_path = os.path.dirname(os.path.realpath(__file__))

kv_file_path = os.path.join(dir_path, 'favorites.kv')

Builder.load_file(kv_file_path)

class Favorites(BaseScreen):

    def back(self):
        App.get_running_app().navigate_to_main("right")


    def save_location(self):
        try:
            loc = LocationManager.get_location()
            address = LocationManager.get_human_short_address(loc)
            poi = Poi(lat=loc[0], lon=loc[1], name=address, desc=None)        
            PoiManager.add(poi)
            say( _("{} wurde in 'Orte' gespeichert.").format(address))
        except Exception as e:
            print(e)
            say(_("Leider ist ein Fehler aufgetreten. Ort konnte nicht gespeichert werden"))


    def testdata(self):
        PoiManager.add( Poi(name="Lidl", desc="Lidl in Edingen Neckarhausen", lat=49.45622156121109, lon=8.596111485518252))
        print("Testdaten hinzugefügt")