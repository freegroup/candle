from kivy.config import Config
Config.set('graphics', 'width', '500')  # Set the width of the window
Config.set('graphics', 'height', '900')  # Set the height of the window

from kivy.app import App
from kivy.uix.screenmanager import ScreenManager, SlideTransition
from kivy.core.window import Window
from kivy.clock import Clock

import asyncio
import threading
import logging

from screens.main import Main
from screens.compass import Compass
from screens.record import Record
from screens.select_device import SelectDevice
from screens.permissions import Permissions
from screens.confirm import Confirm
from screens.confirm_exit import ConfirmExit
from screens.navigation import Navigation
from screens.poi_details import PoiDetails
from screens.poi_direction import PoiDirection
from screens.pois import Pois
from utils.location import LocationManager
from utils.compass import CompassManager
from utils.i18n import setup_i18n, _
from utils.tts import say
from utils.permissions import has_all_permissions

logging.getLogger("bleak").setLevel(logging.INFO)


def start_location_services(dt):
    # Starten Sie hier GPS und Kompass
    LocationManager.start()
    CompassManager.start()

class CandleApp(App):

    def build(self):
        setup_i18n()
        self.loop = asyncio.new_event_loop()

        Window.bind(on_request_close=self.on_request_close)

        self.sm = ScreenManager()
        self.sm.add_widget(Main(name='main'))
        self.sm.add_widget(Record(name='record'))
        self.sm.add_widget(SelectDevice(name='device'))
        self.sm.add_widget(Compass(name='compass'))
        self.sm.add_widget(Confirm(name='confirm'))
        self.sm.add_widget(ConfirmExit(name='confirm_exit'))
        self.sm.add_widget(Navigation(name='navigation'))
        self.sm.add_widget(Pois(name='pois'))
        self.sm.add_widget(PoiDetails(name='poi_details'))
        self.sm.add_widget(Permissions(name='permissions'))
        self.sm.add_widget(PoiDirection(name='poi_direction'))
        
        self.navigate_to_main()
        return self.sm
    

    def on_start(self):
        if has_all_permissions():
            # User has granted all permissions, BUT I must ask for them evertime on startup to get access in location and BLE
            #ask_all_permission()
            Clock.schedule_once(start_location_services, 4)
        else:
            # Inform the user, that now a system menu comes and asks for permissions
            #
            self.navigate_to_permissions()

        # Start the asyncio loop
        self.loop_thread = threading.Thread(target=self.start_asyncio_loop, daemon=True)
        self.loop_thread.start()


    def start_asyncio_loop(self):
        asyncio.set_event_loop(self.loop)
        self.loop.run_forever()


    def on_stop(self):
        self.loop.call_soon_threadsafe(self.loop.stop)
        self.loop_thread.join()
        LocationManager.stop()
        CompassManager.stop()


    def on_request_close(self, *args, **kwargs):
        self.request_terminate()
        return True 


    def close_popup(self):
        self.sm.current = self.previous_screen


    def terminate(self):
        say(_("Programm wird beendet"))
        self.stop()


    def request_terminate(self):
        if LocationManager.is_active():
            self.previous_screen = self.sm.current
            self.sm.current = 'confirm_exit'
        else:
            self.terminate()

    def navigate_to_main(self, dir="left"):
        self._navigate("main", dir)

    def navigate_to_permissions_granted(self, dir="left"):
        Clock.schedule_once(start_location_services, 4)
        self.navigate_to_main(dir)

    def navigate_to_permissions(self, dir="left"):
        self._navigate("permissions", dir)

    def navigate_to_settings(self, dir="left"):
        self._navigate("device", dir)

    def navigate_to_record(self, dir="left"):
        self._navigate("record", dir)

    def navigate_to_compass(self, dir="left"):
        self._navigate("compass", dir)

    def navigate_to_navigation(self, dir="left"):
        self._navigate("navigation", dir)

    def navigate_to_pois(self, dir="left"):
        self._navigate("pois", dir)

    def navigate_to_poi_details(self, poi, dir="left"):
        target_screen = self.sm.get_screen("poi_details")
        target_screen.poi = poi
        target_screen.ids.header.say = _("Details für: {}").format(poi.name)
        self._navigate("poi_details", dir)

    def navigate_to_poi_direction(self, poi, dir="left"):
        target_screen = self.sm.get_screen("poi_direction")
        target_screen.poi = poi
        self._navigate("poi_direction", dir)

    def confirm(self, text, say, on_confirm):
        def _cancel(screen):
            self._navigate(screen, "right")
        
        def _confirm(screen, func):
            self._navigate(screen, "right")
            func()

        current_screen = self.sm.current
        confirm_screen = self.sm.get_screen("confirm")
        confirm_screen.ids.header.text = text
        confirm_screen.ids.header.say = say
        confirm_screen.cancel = lambda screen=current_screen: _cancel(screen)
        confirm_screen.confirm = lambda screen=current_screen: _confirm(screen, on_confirm)

        self._navigate("confirm", "left")


    def _navigate(self, screen, dir):
        self.sm.transition = SlideTransition(direction=dir)
        self.sm.current=screen


async def main():
    app = CandleApp()
    await app.async_run("asyncio")


if __name__ == "__main__":
    asyncio.run(main())
