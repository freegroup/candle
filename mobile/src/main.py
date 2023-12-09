from kivy.config import Config
Config.set('graphics', 'width', '500')  # Set the width of the window
Config.set('graphics', 'height', '900')  # Set the height of the window

from kivy.app import App
from kivy.uix.screenmanager import ScreenManager
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
from screens.confirm_exit import ConfirmExit
from screens.favoriten import Favoriten
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
        self.sm.add_widget(ConfirmExit(name='confirm_exit'))
        self.sm.add_widget(Favoriten(name='favoriten'))
        self.sm.add_widget(Permissions(name='permissions'))
        
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

    def navigate_to_main(self):
        self.sm.current="main"

    def navigate_to_permissions_granted(self):
        Clock.schedule_once(start_location_services, 4)
        self.sm.current="main"

    def navigate_to_permissions(self):
        self.sm.current="permissions"

    def navigate_to_settings(self):
        self.sm.current="device"

    def navigate_to_record(self):
        self.sm.current="record"

    def navigate_to_compass(self):
        self.sm.current="compass"

    def navigate_to_favoriten(self):
        self.sm.current="favoriten"



async def main():
    app = CandleApp()
    await app.async_run("asyncio")


if __name__ == "__main__":
    asyncio.run(main())
