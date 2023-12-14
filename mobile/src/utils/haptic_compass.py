import os
import queue
import asyncio

from kivy.clock import Clock

from bleak import BleakClient

from utils.storage import Storage

CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"

class HapticCompass:
    direction = 0
    # Create a global queue with a maximum size of 2
    ble_send_queue = queue.Queue(maxsize=2)
    ble_task = None  # For tracking the asyncio task


    @classmethod
    def start(cls):
        try:
            cls.ble_task = asyncio.create_task(cls._process_ble_queue())
        except Exception as e:
            print(e)
            print("Compass not implemente on this plattform")

    @classmethod
    def stop(cls):
        try:
            if cls.ble_task and not cls.ble_task.done():
                cls.ble_task.cancel()  # Cancel the BLE processing task
            cls.ble_task = None
        except Exception as e:
            print(e)
            print("Compass not available on this platform")


    @classmethod
    def set_angle(cls, angle):
        device = Storage.get_connected_device()
        if device and not cls.ble_send_queue.full():
            angle = int(angle)
            cls.ble_send_queue.put((device.address, str(angle)))
            print(f"Enqueued compass data '{angle}' for sending")


    @classmethod
    async def _process_ble_queue(cls):
        while True:
            if not cls.ble_send_queue.empty():
                device_address, angle_str = cls.ble_send_queue.get()
                await cls._send_ble_data(device_address, angle_str)
            await asyncio.sleep(0.2)  # Add a small delay to avoid rapid task execution


    @classmethod
    async def _send_ble_data(cls, device_address, angle_str):
        try:
            async with BleakClient(device_address) as client:
                
                if client.is_connected:
                    await client.write_gatt_char(CHARACTERISTIC_UUID, angle_str.encode(), response=True)
                    print(f"Data '{angle_str}' sent successfully")
                else:
                    print("Failed to connect to the BLE device")
        except Exception as e:
            print(f"Failed to send data: {e}")

