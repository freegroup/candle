import time

from kivy.properties import ObjectProperty
from kivy.uix.boxlayout import BoxLayout
from kivy.utils import platform

class Swipe(BoxLayout):
    swipe_left = ObjectProperty(lambda: None)
    swipe_right = ObjectProperty(lambda: None)

    def __init__(self, **kwargs):
        super(Swipe, self).__init__(**kwargs)

    def on_touch_down(self, touch):
        touch.ud['start_pos'] = (touch.x, touch.y)
        touch.ud['start_time'] = time.time()
        return super().on_touch_down(touch)

    def on_touch_up(self, touch):
        if 'start_pos' in touch.ud and 'start_time' in touch.ud:
            end_time = time.time()
            duration = end_time - touch.ud['start_time']

            if duration <= 0.5:  # Check if swipe happened within 0.2 seconds
                dx = touch.x - touch.ud['start_pos'][0]
                dy = touch.y - touch.ud['start_pos'][1]
                width_threshold = self.width * 0.6  # 80% of the screen width
                height_threshold = self.height * 0.2  # 20% of the screen height for vertical tolerance

                if abs(dx) > width_threshold and abs(dy) < height_threshold:
                    if dx > 0:
                       self.vibrate_device()
                       self.swipe_right()
                    else:
                        self.vibrate_device()
                        self.swipe_left()

        return super().on_touch_up(touch)


    def vibrate_device(self, duration=0.05):
        if platform == 'android':
            from plyer import vibrator
            vibrator.vibrate(duration)
        else:
            print("bbbrrrrr.......vibrate")
