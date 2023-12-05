import os
from kivy.app import App
from kivy.uix.screenmanager import Screen
from kivy.lang import Builder

dir_path = os.path.dirname(os.path.realpath(__file__))

kv_file_path = os.path.join(dir_path, 'record.kv')

Builder.load_file(kv_file_path)

class Record(Screen):

    def on_pre_enter(self):
        header = self.ids.header  # Assuming the header has an id 'header' in your kv file
        header.announce()


    def back(self):
        app = App.get_running_app()
        app.main()
   
