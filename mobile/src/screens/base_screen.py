from utils.i18n import _

from kivy.uix.screenmanager import Screen
from kivy.utils import platform

class BaseScreen(Screen):

    def on_pre_enter(self):
        super().on_pre_enter()
        header = self.ids.header  # Assuming the header has an id 'header' in your kv file
        header.announce()



    def vibrate(self, duration=0.05):
        if platform == 'android':
            from plyer import vibrator
            vibrator.vibrate(duration)
        else:
            print("bbbrrrrr.......vibrate")  # Vibrate for 500 milliseconds
 
