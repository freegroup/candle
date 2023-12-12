from kivy.uix.button import Button
from kivy.clock import Clock
import timeit


DOUBLE_TAP_TIME = 0.2   # Change time in seconds
LONG_PRESSED_TIME = 0.3  # Change time in seconds
LONG_DOWN_TIME = 0.5     # Zeit in Sekunden, um anhaltendes Langdrücken zu erkennen


class MultiButton(Button):

    def __init__(self, **kwargs):
        super(MultiButton, self).__init__(**kwargs)
        self.start = 0
        self.single_hit = 0
        self.press_state = False
        self.register_event_type('on_single_press')
        self.register_event_type('on_double_press')
        self.register_event_type('on_long_press')

    def on_touch_down(self, touch):
        if self.collide_point(touch.x, touch.y):
            self.start = timeit.default_timer()
            if touch.is_double_tap:
                self.press_state = True
                self.single_hit.cancel()
                self.dispatch('on_double_press')
        else:
            return super(MultiButton, self).on_touch_down(touch)

    def on_touch_up(self, touch):
        if self.press_state is False:
            if self.collide_point(touch.x, touch.y):
                stop = timeit.default_timer()
                awaited = stop - self.start

                def not_double(time):
                    nonlocal awaited
                    if awaited > LONG_PRESSED_TIME:
                        self.dispatch('on_long_press')
                    else:
                        self.dispatch('on_single_press')

                self.single_hit = Clock.schedule_once(not_double, DOUBLE_TAP_TIME)
            else:
                return super(MultiButton, self).on_touch_down(touch)
        else:
            self.press_state = False

    def on_single_press(self):
        print("single_press")
        pass

    def on_double_press(self):
        print("double_press")
        pass

    def on_long_press(self):
        print("long_press")
        pass