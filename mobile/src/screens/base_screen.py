from utils.i18n import _

from kivy.uix.screenmanager import Screen


class BaseScreen(Screen):

    def on_pre_enter(self):
        super().on_pre_enter()
        header = self.ids.header  # Assuming the header has an id 'header' in your kv file
        header.announce()

