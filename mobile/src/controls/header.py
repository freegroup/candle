import os
import threading


from kivy.clock import Clock
from kivy.uix.boxlayout import BoxLayout
from kivy.properties import StringProperty, ObjectProperty, BooleanProperty

from kivy.lang import Builder

from plyer import tts

# Load the KV file for this module
Builder.load_file(os.path.join(os.path.dirname(__file__), 'header.kv'))

def tts_speak(text):
    tts.speak(message=text)


class Header(BoxLayout):
    text = StringProperty('')
    say = StringProperty('')

    def announce(self):
        threading.Thread(target=tts_speak, args=(self.say,)).start()

