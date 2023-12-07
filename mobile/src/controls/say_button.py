import os
import threading

from kivy.clock import Clock
from kivy.uix.boxlayout import BoxLayout
from kivy.properties import StringProperty, ObjectProperty, BooleanProperty
from kivy.uix.button import Button

from kivy.lang import Builder

from plyer import vibrator
from plyer import tts

# Load the KV file for this module
Builder.load_file(os.path.join(os.path.dirname(__file__), 'say_button.kv'))


class CustomButton(Button):
    def on_touch_move(self, touch):
        return False  # Continue propagating the event

def tts_speak(text):
    tts.speak(message=text)

class SayButton(BoxLayout):
    text = StringProperty('')
    say = StringProperty('')
    action = ObjectProperty(None)
    long_press_time = 0.5  # Time in seconds for long press
    long_press_event = None
    last_inside = BooleanProperty(False)

    def on_touch_down(self, touch):
        if self.collide_point(*touch.pos):
            self.vibrate_device()
            self.start_long_press_timer(touch)
        return super(SayButton, self).on_touch_down(touch)

    def on_touch_move(self, touch):
        inside = self.collide_point(*touch.pos)
        if inside and not self.last_inside:
            self.vibrate_device()
            self.start_long_press_timer(touch)
        elif not inside and self.last_inside:
            self.cancel_long_press_timer()
        self.last_inside = inside
        return super(SayButton, self).on_touch_move(touch)

    def on_touch_up(self, touch):
        self.cancel_long_press_timer()
        if self.collide_point(*touch.pos) and self.action:
            self.action()
        return super(SayButton, self).on_touch_up(touch)

    def start_long_press_timer(self, touch):
        self.cancel_long_press_timer()
        self.long_press_event = Clock.schedule_once(lambda dt: self.on_long_press(touch), self.long_press_time)

    def cancel_long_press_timer(self):
        if self.long_press_event:
            Clock.unschedule(self.long_press_event)
            self.long_press_event = None

    def on_long_press(self, touch):
        # Your long press action, e.g., TTS or sound playback
        self.tts(self.say)


    def vibrate_device(self, duration=0.05):
        try:
            if vibrator.exists():  # Check if the vibrator exists on the device
                vibrator.vibrate(duration)
        except:
            print("vibrate not supported")


    def tts(self, text):
        print(text)
        threading.Thread(target=tts_speak, args=(text,)).start()


    def on_button_release(self):
        if self.action:
            self.action()