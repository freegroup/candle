import os

from kivy.app import App
from screens.base_screen import BaseScreen
from kivy.lang import Builder
from utils.i18n import _
from utils.tts import say

dir_path = os.path.dirname(os.path.realpath(__file__))
kv_file_path = os.path.join(dir_path, 'confirm.kv')

Builder.load_file(kv_file_path)

class Confirm(BaseScreen):
    confirm = None
    cancel = None

    def confirm(self):
        if self.confirm:
            self.confirm()

    def cancel(self):
        if self.cancel:
            self.cancel()
