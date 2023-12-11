import os

from kivy.clock import Clock
from kivy.uix.boxlayout import BoxLayout
from kivy.properties import StringProperty, ObjectProperty, BooleanProperty, ListProperty, NumericProperty
from kivy.uix.button import Button
from kivy.utils import get_color_from_hex
from kivy.utils import platform
from kivy.lang import Builder
import time

from utils.tts import say as tts_say

# Load the KV file for this module
Builder.load_file(os.path.join(os.path.dirname(__file__), 'say_button.kv'))


class CustomButton(Button):
    def on_touch_move(self, touch):
        return False  # Continue propagating the event

def adjust_color_brightness(color, brightness_factor):
    """
    Adjusts the brightness of a given color.
    :param color: A list of RGBA values (between 0 and 1)
    :param brightness_factor: A float value. >1 to brighten, <1 to darken
    :return: A list of adjusted RGBA values
    """
    r, g, b, a = color
    return [max(min(c * brightness_factor, 1), 0) for c in (r, g, b)] + [a]


class SayButton(BoxLayout):
    text = StringProperty('')
    say = StringProperty('')
    action = ObjectProperty(None)
    vibrate = NumericProperty(1)  # Custom property
    long_press_time = 1.0  # Time in seconds for long press
    long_press_event = None
    long_pressed = BooleanProperty(False) 
    last_inside = BooleanProperty(False)
    normal_color = ListProperty([1, 1, 1, 1])  # default normal color
    pressed_color = ListProperty([1, 1, 1, 1])  # default pressed color

    def __init__(self, **kwargs):
        super(SayButton, self).__init__(**kwargs)
        # Wait for the next frame to let all widgets be drawn
        Clock.schedule_once(self._capture_default_color)

    def _capture_default_color(self, dt):
        button = self.ids.custom_button
        self.normal_color = button.background_color
        self.pressed_color = adjust_color_brightness(self.normal_color, 1.5)
        button.background_normal = ''
        button.background_down = ''

    def on_touch_down(self, touch):
        r = super(SayButton, self).on_touch_down(touch)
        if self.collide_point(*touch.pos):
            self.vibrate_device()
            self.start_long_press_timer(touch)        
            self.ids.custom_button.background_color = self.pressed_color

        return r

    def on_touch_move(self, touch):
        inside = self.collide_point(*touch.pos)
        if inside and not self.last_inside:
            self.vibrate_device()
            self.start_long_press_timer(touch)
            self.ids.custom_button.background_color = self.pressed_color 
        elif not inside and self.last_inside:
            self.cancel_long_press_timer()
            self.ids.custom_button.background_color = self.normal_color

        self.last_inside = inside
        return super(SayButton, self).on_touch_move(touch)


    def on_touch_up(self, touch):
        self.cancel_long_press_timer()
        if self.collide_point(*touch.pos) and self.action and self.long_pressed==False:
            self.action()
        self.long_pressed = False
        self.ids.custom_button.background_color = self.normal_color
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
        tts_say(self.say)
        self.long_pressed = True 


    def vibrate_device(self, duration=0.05):
        if platform == 'android':
            from plyer import vibrator
            vibrator.vibrate(duration*self.vibrate)
        else:
            print("bbbrrrrr.......vibrate")  # Vibrate for 500 milliseconds
 

    def on_button_release(self):
        if self.action:
            self.action()
        self.ids.custom_button.background_color = self.normal_color
