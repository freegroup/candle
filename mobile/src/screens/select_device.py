import os
import asyncio

from kivy.lang import Builder
from kivy.uix.widget import Widget
from kivy.app import App

from bleak import BleakScanner

from controls.say_button import SayButton
from screens.base_screen import BaseScreen
from utils.storage import Storage
from utils.i18n import _
from utils.tts import say

dir_path = os.path.dirname(os.path.realpath(__file__))
kv_file_path = os.path.join(dir_path, 'select_device.kv')
Builder.load_file(kv_file_path)

class SelectDevice(BaseScreen):

    def back(self):
        App.get_running_app().navigate_to_main("right")

    def on_pre_enter(self):
        super().on_pre_enter()
        self.populate_devices([])
        self.scan_in_progress = False


    def start_ble_scan(self):
        if self.scan_in_progress:
            say("Suche nach bereits nach Geräte...bitte etwas geduld.")  # Avoid duplicate scans
            return
         
        say("Starte suche nach kompatiblen Geräten...")
        asyncio.create_task(self.scan_and_populate_devices())


    async def scan_and_populate_devices(self):
        print("discover devices...")
        try:
            devices = await BleakScanner.discover()
            if len(devices)>0:
                say("Es wurden Geräte gefunden, bitte ein Gerät aus der Liste auswählen")
            else:
                say("Es konnten leider keine Geräte gefunden werden. Eventell ist dein Candle nicht eingeschaltet.")

            self.populate_devices(devices)
        except Exception as e:
            print(e)
            say("Leider ist ein Fehler bei der Suche von neuen Geräten passiert. Es konnten keine neuen Geräte gefnden werden")
        self.scan_in_progress = False 

    def populate_devices(self, devices):
        current_device = Storage.get_connected_device()
        current_device_found = False
        devices_list = self.ids.devices_list
        devices_list.clear_widgets()
        for device in devices:
            if device.name:
                button_text = device.name
                button_say = f"Verbinden mit {device.name}?"
                if current_device and device.address == current_device.address:
                    current_device_found = True
                    button_text = button_text + " (connected)"
                    button_say = f"{device.name}. Mit diesem Gerät sind sie bereits verbunden."
                button = SayButton(
                    text=button_text, 
                    say=button_say, 
                    action=lambda d=device: self.connect_to_device(d)
                )
                devices_list.add_widget(button)
        
        # add the already connected device even if it is currently not found.
        # Do not delete a connected device by accident
        #
        if current_device and current_device_found==False:
            button_text = current_device.name + " (connected)"
            button_say = f"{current_device.name}. Mit diesem Gerät sind sie bereits verbunden."
            button = SayButton(
                text=button_text, 
                say=button_say, 
                action=lambda d=current_device: self.connect_to_device(d)
            )
            devices_list.add_widget(button)
        
        button = SayButton(
            text="Geräte suchen", 
            say="Erneut nach kompatiblen Geräten suchen.", 
            action=lambda: self.start_ble_scan()
        )
        devices_list.add_widget(button)

        # Add spacer
        spacer = Widget(size_hint_y=1)
        devices_list.add_widget(spacer)


    def connect_to_device(self, device):
        say(f"Ich verbinde mich mit dem Gerät: {device.name}.")
        Storage.set_connected_device(device)

 