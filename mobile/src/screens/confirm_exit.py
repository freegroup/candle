import os

from kivy.app import App
from screens.base_screen import BaseScreen
from kivy.lang import Builder

dir_path = os.path.dirname(os.path.realpath(__file__))
kv_file_path = os.path.join(dir_path, 'confirm_exit.kv')

Builder.load_file(kv_file_path)

class ConfirmExit(BaseScreen):
    pass
