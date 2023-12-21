import os

from kivy.lang import Builder
from kivy.clock import Clock
from kivy.app import App

from screens.base_screen import BaseScreen
from kivy.properties import NumericProperty
from utils.tts import say

from utils.i18n import _
from utils.compass import CompassManager
from utils.haptic_compass import HapticCompass

dir_path = os.path.dirname(os.path.realpath(__file__))
kv_file_path = os.path.join(dir_path, 'compass.kv')
image_path = os.path.join(dir_path, 'compass.png') 
Builder.load_file(kv_file_path)



class Compass(BaseScreen):
    needle_angle = NumericProperty(0)  # Add this line

    def back(self):
        App.get_running_app().navigate_to_main("right")

    def on_enter(self):
        self.ids.arrow.source = image_path  # Set the full path to the image 
        Clock.schedule_interval(self.update_compass, 1 / 20)


    def on_leave(self):
        Clock.unschedule(self.update_compass)


    def update_compass(self, dt):
        self.needle_angle = CompassManager.get_angle()
        # HapticCompass should point to NORTH. this is the idea of an compass ats it's own
        #
        HapticCompass.set_angle(0)


    def say_horizon(self, angle):
        directions = [
            _("Norden"), _("Nord-Nordost"), _("Nordost"), _("Ost-Nordost"),
            _("Osten"), _("Ost-Südost"), _("Südost"), _("Süd-Südost"),
            _("Süden"), _("Süd-Südwest"), _("Südwest"), _("West-Südwest"),
            _("Westen"), _("West-Nordwest"), _("Nordwest"), _("Nord-Nordwest")
        ]
        segment = round(angle / 22.5) % 16
        return (_("Sie halten das Handy in Richtung {}").format(directions[segment]))


    def say_angle(self):
        # Runden des Winkels auf das nächste Vielfache von 5
        rounded_angle = round(CompassManager.get_angle() / 5) * 5

        # Toleranz für die Nähe zu den Haupt-Himmelsrichtungen
        tolerance = 10

        # Hilfsfunktion zur Überprüfung, ob der Winkel nahe an einer Himmelsrichtung liegt
        def is_near(main_angle, angle, tolerance):
            return abs(main_angle - angle) <= tolerance

        # Erstellen der Ansage
        if is_near(0, rounded_angle, tolerance) or is_near(360, rounded_angle, tolerance):
            if rounded_angle == 0 or rounded_angle == 360:
                say(_("Sie halten das Handy genau in Richtung 0 Grad, also Norden"))
            else:
                say(_("Sie halten das Handy in Richtung {} Grad, das ist fast genau Norden").format(rounded_angle))
        elif is_near(90, rounded_angle, tolerance):
            if rounded_angle == 90:
                say(_("Sie halten das Handy genau in Richtung 90 Grad, also Osten"))
            else:
                say(_("Sie halten das Handy in Richtung {} Grad, das ist fast genau Osten").format(rounded_angle))
        elif is_near(180, rounded_angle, tolerance):
            if rounded_angle == 180:
                say(_("Sie halten das Handy genau in Richtung 180 Grad, also Süden"))
            else:
                say(_("Sie halten das Handy in Richtung {} Grad, das ist fast genau Süden").format(rounded_angle))
        elif is_near(270, rounded_angle, tolerance):
            if rounded_angle == 270:
                say(_("Sie halten das Handy genau in Richtung 270 Grad, also Westen"))
            else:
                say(_("Sie halten das Handy in Richtung {} Grad, das ist fast genau Westen").format(rounded_angle))
        else:
            say(_("Sie halten das Handy in Richtung {} Grad").format(rounded_angle))
