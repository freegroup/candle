import os

from kivy.uix.boxlayout import BoxLayout
from kivy.properties import StringProperty, ObjectProperty, BooleanProperty
from kivy.uix.button import Button

from kivy.lang import Builder
from kivy.core.audio import SoundLoader

from plyer import vibrator
from plyer import tts

# Load the KV file for this module
Builder.load_file(os.path.join(os.path.dirname(__file__), 'say_button.kv'))


class CustomButton(Button):
    def on_touch_move(self, touch):
        return False  # Continue propagating the event

class SayButton(BoxLayout):
    text = StringProperty('')
    say = StringProperty('')
    on_release = ObjectProperty(None)

    last_inside = BooleanProperty(False)  # Flag to track if the last touch move was inside SayButton

    def on_touch_move(self, touch):

        inside = self.collide_point(*touch.pos)
        if inside and not self.last_inside:
            # The touch has just entered the SayButton area
            self.vibrate_device()
        self.last_inside = inside  # Update the flag based on the current touch position
        return super(SayButton, self).on_touch_move(touch)

    def vibrate_device(self, duration=0.05):
        try:
            if vibrator.exists():  # Check if the vibrator exists on the device
                vibrator.vibrate(duration)
        except:
            print("vibrate not supported")

    def tts(self, text):
        tts.speak(message=text)

    def play_sound(self, sound_file):
        base_path = os.path.dirname(__file__)  # Already in the src directory
        base_path = os.path.join(base_path, '../')
        sound_path = os.path.join(base_path, 'sounds', sound_file)

        sound_path = os.path.normpath(sound_path) 
        print("play sound:"+sound_path)
        if not os.path.exists(sound_path):
            print("Sound file do not exits:"+sound_path)
            for root, dirs, files in os.walk(base_path):
                level = root.replace(base_path, '').count(os.sep)
                indent = ' ' * 4 * (level)
                print(f"{indent}{os.path.basename(root)}/")
                subindent = ' ' * 4 * (level + 1)
                for f in files:
                    print(f"{subindent}{f}")

        sound = SoundLoader.load(sound_path)
        if sound:
            sound.play()
        else:
            print("Sound file not playable:"+sound_path)


    def custom_action(self):
        print("do action")
