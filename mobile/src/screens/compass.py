import os

from kivy.lang import Builder
from kivy.clock import Clock
from screens.base_screen import BaseScreen
from kivy.properties import NumericProperty
from utils.storage import Storage
from utils.tts import say
from bleak import BleakClient
import asyncio
import queue

from utils.i18n import _
from utils.compass import CompassManager

dir_path = os.path.dirname(os.path.realpath(__file__))
kv_file_path = os.path.join(dir_path, 'compass.kv')
image_path = os.path.join(dir_path, 'compass.png') 
Builder.load_file(kv_file_path)

CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"

# Create a global queue with a maximum size of 2
ble_send_queue = queue.Queue(maxsize=2)



class Compass(BaseScreen):
    needle_angle = NumericProperty(0)  # Add this line
    ble_task = None  # For tracking the asyncio task


    def on_enter(self):
        self.ids.arrow.source = image_path  # Set the full path to the image 
        try:
            Clock.schedule_interval(self.update_compass, 1 / 20)
            self.ble_task = asyncio.create_task(self.process_ble_queue())
        except Exception as e:
            print(e)
            print("Compass not implemente on this plattform")


    def on_leave(self):
        try:
            Clock.unschedule(self.update_compass)
            if self.ble_task and not self.ble_task.done():
                self.ble_task.cancel()  # Cancel the BLE processing task
            self.ble_task = None
        except Exception as e:
            print(e)
            print("Compass not available on this platform")


    def update_compass(self, dt):
        try:
            self.needle_angle   = CompassManager.get_angle()
            print("Needle Angle:" + str(self.needle_angle))
            device = Storage.get_connected_device()
            if device:
                self.enqueue_ble_data(device.address, CompassManager.get_angle())
        except Exception as e:
            print(e)
            print("Compass is not implemented for your platform")


    def enqueue_ble_data(self, device_address, angle):
        if not ble_send_queue.full():
            ble_send_queue.put((device_address, str(angle)))
            print("Enqueued data for sending")

    async def process_ble_queue(self):
        while True:
            if not ble_send_queue.empty():
                device_address, angle_str = ble_send_queue.get()
                await self.send_ble_data(device_address, angle_str)
            await asyncio.sleep(0.25)  # Add a small delay to avoid rapid task execution

    async def send_ble_data(self, device_address, angle_str):
        try:
            async with BleakClient(device_address) as client:
                if client.is_connected:
                    await client.write_gatt_char(CHARACTERISTIC_UUID, angle_str.encode(), response=False)
                    print("Data sent successfully")
                else:
                    print("Failed to connect to the BLE device")
        except Exception as e:
            print(f"Failed to send data: {e}")


    def say_horizon(self):
        directions = [
            _("Norden"), _("Nord-Nordost"), _("Nordost"), _("Ost-Nordost"),
            _("Osten"), _("Ost-Südost"), _("Südost"), _("Süd-Südost"),
            _("Süden"), _("Süd-Südwest"), _("Südwest"), _("West-Südwest"),
            _("Westen"), _("West-Nordwest"), _("Nordwest"), _("Nord-Nordwest")
        ]
        segment = round(CompassManager.get_angle() / 22.5) % 16
        say(_("Sie halten das Handy in Richtung {}").format(directions[segment]))


    def say_angle(self):
        # Runden des Winkels auf das nächste Vielfache von 5
        rounded_angle = round(CompassManager.get_angle() / 5) * 5

        # Toleranz für die Nähe zu den Haupt-Himmelsrichtungen
        tolerance = 10

        # Hilfsfunktion zur Überprüfung, ob der Winkel nahe an einer Himmelsrichtung liegt
        def is_near(main_angle, angle, tolerance):
            return abs(main_angle - angle) <= tolerance

        # Erstellen der Ansage
        if is_near(0, rounded_angle, tolerance) or is_near(360, rounded_angle, tolerance):
            if rounded_angle == 0 or rounded_angle == 360:
                say(_("Sie halten das Handy genau in Richtung 0 Grad, also Norden"))
            else:
                say(_("Sie halten das Handy in Richtung {} Grad, das ist fast genau Norden").format(rounded_angle))
        elif is_near(90, rounded_angle, tolerance):
            if rounded_angle == 90:
                say(_("Sie halten das Handy genau in Richtung 90 Grad, also Osten"))
            else:
                say(_("Sie halten das Handy in Richtung {} Grad, das ist fast genau Osten").format(rounded_angle))
        elif is_near(180, rounded_angle, tolerance):
            if rounded_angle == 180:
                say(_("Sie halten das Handy genau in Richtung 180 Grad, also Süden"))
            else:
                say(_("Sie halten das Handy in Richtung {} Grad, das ist fast genau Süden").format(rounded_angle))
        elif is_near(270, rounded_angle, tolerance):
            if rounded_angle == 270:
                say(_("Sie halten das Handy genau in Richtung 270 Grad, also Westen"))
            else:
                say(_("Sie halten das Handy in Richtung {} Grad, das ist fast genau Westen").format(rounded_angle))
        else:
            say(_("Sie halten das Handy in Richtung {} Grad").format(rounded_angle))
