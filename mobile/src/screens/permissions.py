import os
from kivy.app import App
from screens.base_screen import BaseScreen
from kivy.lang import Builder
from kivy.clock import Clock

from utils.i18n import _
from utils.tts import say
from utils.permissions import ask_all_permission, has_all_permissions

dir_path = os.path.dirname(os.path.realpath(__file__))

kv_file_path = os.path.join(dir_path, 'permissions.kv')

Builder.load_file(kv_file_path)

class Permissions(BaseScreen):
    def on_enter(self):
        self.request_permissions()
        # Periodische Überprüfung der Berechtigungen
        self.permission_check_event = Clock.schedule_interval(self.check_permissions, 1)

    def on_leave(self):
        # Sicherstellen, dass der Clock-Event abgebrochen wird, wenn der Bildschirm verlassen wird
        if self.permission_check_event:
            self.permission_check_event.cancel()

    def request_permissions(self):
        say(_("Berechtigungen werden nun von ihrem Telefon erfragt. Bitte diese bestätigen, damit sie das Programm nutzen können."))
        ask_all_permission()


    def check_permissions(self, dt):
        if has_all_permissions():
            # Berechtigungen wurden erteilt, Clock-Event abbrechen
            self.permission_check_event.cancel()
            # Navigieren zu einer anderen Funktion
            App.get_running_app().navigate_to_permissions_granted()        
   
