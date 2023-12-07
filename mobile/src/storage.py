import json
import os
from collections import namedtuple
from kivy.app import App

class Storage:
    data_loaded = False
    data = {}

    @staticmethod
    def get_filename():
        filename = App.get_running_app().user_data_dir + "/shared_preferences.json"
        print("Storage File: "+ filename)
        return filename

    @staticmethod
    def load():
        if not Storage.data_loaded:
            try:
                with open(Storage.get_filename(), 'r') as f:
                    Storage.data = json.load(f)
                Storage.data_loaded = True
            except (FileNotFoundError, json.JSONDecodeError) as e:
                print(f"Error loading preferences file: {e}")
                Storage.data = {}

    @staticmethod
    def save():
        with open(Storage.get_filename(), 'w') as f:
            json.dump(Storage.data, f, indent=4)


    @staticmethod
    def get(key):
        Storage.load()
        if key not in Storage.data:
            return None
        return Storage.data[key]


    @staticmethod
    def set(key, value):
        Storage.load()
        if value is None:
            Storage.data[key] = None
        else:
            Storage.data[key] = value
        Storage.save()


    @staticmethod
    def delete(key):
        if key in Storage.data:
            del Storage.data[key]

    @staticmethod
    def get_connected_device():
        Device = namedtuple('Device', ['name', 'address'])
        name = Storage.get("device_name")
        address = Storage.get("device_address")
        if address and name:
            return Device(name=name, address=address)
        return None  

    @staticmethod
    def set_connected_device(device):
        Storage.set("device_name", device.name)
        Storage.set("device_address", device.address)

 
