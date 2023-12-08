import os

from kivy.uix.boxlayout import BoxLayout
from kivy.properties import StringProperty

from kivy.lang import Builder

from utils.tts import say as tts_say

# Load the KV file for this module
Builder.load_file(os.path.join(os.path.dirname(__file__), 'header.kv'))

class Header(BoxLayout):
    text = StringProperty('')
    say = StringProperty('')

    def announce(self):
       tts_say(self.say,)

