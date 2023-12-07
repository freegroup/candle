import os
import threading
from plyer import tts

from kivy.uix.screenmanager import Screen


def tts_speak(text):
    tts.speak(message=text)

class BaseScreen(Screen):

    def on_pre_enter(self):
        super().on_pre_enter()
        header = self.ids.header  # Assuming the header has an id 'header' in your kv file
        header.announce()

    def tts(self, text):
        print(text)
        threading.Thread(target=tts_speak, args=(text,)).start()

