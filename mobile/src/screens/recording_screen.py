import os
from kivy.app import App
from kivy.uix.screenmanager import Screen
from kivy.lang import Builder

dir_path = os.path.dirname(os.path.realpath(__file__))

kv_file_path = os.path.join(dir_path, 'recording_screen.kv')

Builder.load_file(kv_file_path)

class RecordingScreen(Screen):

    def back(self):
        app = App.get_running_app()
        app.set_screen("main")
        print("back called")
        
