import os
from math import floor, degrees

from plyer.utils import platform
from kivy.lang import Builder
from kivy.clock import Clock
from plyer import spatialorientation
from screens.base_screen import BaseScreen
from kivy.properties import NumericProperty
from utils.storage import Storage
from utils.tts import say
from bleak import BleakClient
import asyncio
import queue

from utils.i18n import _

dir_path = os.path.dirname(os.path.realpath(__file__))
kv_file_path = os.path.join(dir_path, 'compass.kv')
image_path = os.path.join(dir_path, 'compass.png') 
Builder.load_file(kv_file_path)

CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"

# Create a global queue with a maximum size of 2
ble_send_queue = queue.Queue(maxsize=2)


def check_bluetooth_permissions():
    if platform == "android":
        from android.permissions import check_permission, Permission
        if not check_permission(Permission.BLUETOOTH_CONNECT):
            print("BLUETOOTH_CONNECT permission not granted")
        else: 
            print("BLUETOOTH_CONNECT permissions GRANTED!!!")


class Compass(BaseScreen):
    needle_angle = NumericProperty(0)  # Add this line
    ble_task = None  # For tracking the asyncio task


    def on_enter(self):
        self.ids.arrow.source = image_path  # Set the full path to the image 
        try:
            spatialorientation.enable_listener()
            Clock.schedule_interval(self.update_compass, 1 / 20)
            self.ble_task = asyncio.create_task(self.process_ble_queue())
            check_bluetooth_permissions()
        except Exception as e:
            print(e)
            print("Compass not implemente on this plattform")


    def on_leave(self):
        try:
            spatialorientation.disable_listener()
            Clock.unschedule(self.update_compass)
            if self.ble_task and not self.ble_task.done():
                self.ble_task.cancel()  # Cancel the BLE processing task
            self.ble_task = None
        except Exception as e:
            print(e)
            print("Compass not available on this platform")


    def update_compass(self, dt):
        try:
            orientation = spatialorientation.orientation
            if orientation:
                azimuth, pitch, roll = orientation
                if azimuth:
                    azimuth_deg = degrees(azimuth)
                    # Normalize the azimuth to be within 0-360 degrees
                    azimuth_deg = azimuth_deg % 360

                    print("Needle Angle:" + str(azimuth_deg))
                    self.needle_angle   = azimuth_deg
                    self.ids.angle.text = f"Angle: {azimuth_deg}"

                    device = Storage.get_connected_device()
                    if device:
                        self.enqueue_ble_data(device.address, azimuth_deg)
            else:
                print("Unable to get Compass data")
        except NotImplementedError:
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