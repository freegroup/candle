from kivy.config import Config
Config.set('graphics', 'width', '500')  # Set the width of the window
Config.set('graphics', 'height', '900')  # Set the height of the window

from kivy.app import App
from kivy.uix.screenmanager import ScreenManager
from kivy.core.window import Window
from plyer import tts
from kivy.clock import Clock
import asyncio
import threading
import logging

from plyer.utils import platform


from screens.main import Main
from screens.compass import Compass
from screens.record import Record
from screens.select_device import SelectDevice
from screens.confirm_exit import ConfirmExit
from gps.location import LocationManager

logging.getLogger("bleak").setLevel(logging.INFO)


class CandleApp(App):

    def build(self):
        self.loop = asyncio.new_event_loop()

        Window.bind(on_request_close=self.on_request_close)

        LocationManager.start()

        self.sm = ScreenManager()
        self.sm.add_widget(Main(name='main'))
        self.sm.add_widget(Record(name='record'))
        self.sm.add_widget(SelectDevice(name='device'))
        self.sm.add_widget(Compass(name='compass'))
        self.sm.add_widget(ConfirmExit(name='confirm_exit'))
        
        self.main()

        if platform == "android":
            from android.permissions import request_permissions, Permission
            request_permissions([Permission.BLUETOOTH_SCAN,  Permission.BLUETOOTH, Permission.BLUETOOTH_CONNECT, Permission.ACCESS_COARSE_LOCATION, Permission.ACCESS_FINE_LOCATION])

        return self.sm
    
    def on_start(self):
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


    def on_request_close(self, *args, **kwargs):
        self.request_terminate()
        return True 


    def close_popup(self):
        self.sm.current = self.previous_screen


    def terminate(self):
        tts.speak(message="Programm wird beendet")
        self.stop()

    def request_terminate(self):
        if self.gps_tracker.is_active():
            self.previous_screen = self.sm.current
            self.sm.current = 'confirm_exit'
        else:
            self.terminate()


    def main(self):
        self.sm.current="main"


    def settings_device(self):
        self.sm.current="device"


    def record(self):
        self.sm.current="record"


    def navigate_to_compass(self):
        self.sm.current="compass"



async def main():
    app = CandleApp()
    await app.async_run("asyncio")


if __name__ == "__main__":
    asyncio.run(main())
