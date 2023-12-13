import os
from kivy.app import App
from screens.base_screen import BaseScreen
from kivy.lang import Builder
from kivy.clock import Clock

from utils.i18n import _
from utils.tts import say
from utils.poi import Poi, PoiManager
from utils.location import LocationManager
from plyer import stt

dir_path = os.path.dirname(os.path.realpath(__file__))

kv_file_path = os.path.join(dir_path, 'poi_details.kv')

Builder.load_file(kv_file_path)

class PoiDetails(BaseScreen):
    poi = None  # Attribute to hold the passed POI


    def back(self):
        App.get_running_app().navigate_to_pois("right")


    def delete(self):
        def confirm():
            PoiManager.delete(self.poi)
            say(_("Ort wurde gelöscht"))
            self.back()

        App.get_running_app().confirm("Löschen", _("Ort: {}, wirklich löschen?").format(self.poi.name), confirm)


    def navigate(self):
        App.get_running_app().navigate_to_poi_routing(self.poi)


    def direction(self):
        App.get_running_app().navigate_to_poi_direction(self.poi)


    def rename(self):
        if stt.listening:
            self.stop_listening()
            return

        stt.start()
        print("Start Recording")

        Clock.schedule_interval(self.check_state, 1)

    def stop_listening(self):
        stt.stop()
        self.update()
        Clock.unschedule(self.check_state)
        print("stop recording")

    def check_state(self, dt):
        # if the recognizer service stops, change UI
        if not stt.listening:
            self.stop_listening()

    def update(self):
        # Process partial and final results
        if stt.results:
            # Assuming we take the last result as the valid one
            last_valid_result = stt.results[-1]
            old_name = self.poi.name
            PoiManager.delete(self.poi)
            self.poi.name = last_valid_result
            PoiManager.add(self.poi)
            say( _("Ort wurde von: {} , nach: {} umbenannt").format(old_name, last_valid_result))
            print(f"Final STT Result: {last_valid_result}")
        else:
            # You can process partial results if needed
            say( _("Konnte Ort nicht umbenennen. Bitte nochmal versuchen und den neuen Namen deutlich in das Mikrophon sprechen."))

