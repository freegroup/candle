import os
from kivy.app import App
from screens.base_screen import BaseScreen
from kivy.lang import Builder
from utils.i18n import _
from utils.tts import say
from utils.poi import Poi, PoiManager
from utils.location import LocationManager
from controls.say_button import SayButton
from controls.border_widget import BorderWidget

dir_path = os.path.dirname(os.path.realpath(__file__))

kv_file_path = os.path.join(dir_path, 'pois.kv')

Builder.load_file(kv_file_path)
class Pois(BaseScreen):
    current_page = 0
    pois_per_page = 8

    def back(self):
        App.get_running_app().navigate_to_navigation("right")

    def on_enter(self, *args):
        super(Pois, self).on_enter(*args)
        self.load_pois()

    def load_pois(self):
        all_pois = PoiManager.get_all()
        pages = [all_pois[i:i + self.pois_per_page] for i in range(0, len(all_pois), self.pois_per_page)]

        if self.current_page >= len(pages):
            self.current_page = 0  # Reset to first page if out of range

        self.ids.poi_list.clear_widgets()
        for poi in pages[self.current_page]:
            self.ids.poi_list.add_widget(SayButton(text=poi.name, say=poi.name,  size_hint_y=1, action=lambda x, poi=poi: self.on_poi_select(poi)))

        # Fill up with placeholder Widgets if needed
        for _ in range(self.pois_per_page - len(pages[self.current_page])):
            self.ids.poi_list.add_widget(BorderWidget(size_hint_y=1))

        if len(all_pois) > self.pois_per_page:
            self.add_navigation_buttons(len(pages))

    def add_navigation_buttons(self, total_pages):
        if self.current_page > 0:
            self.ids.poi_list.add_widget(SayButton(text='Previous', say="Vorgänger", action=self.go_previous))

        if self.current_page < total_pages - 1:
            self.ids.poi_list.add_widget(SayButton(text='Next', say="Weitere Orte", action=self.go_next))

        # Fill with placeholder widgets if necessary
        for _ in range(self.pois_per_page - len(self.ids.poi_list.children) + 2):
            self.ids.poi_list.add_widget(BorderWidget())

    def go_next(self, *args):
        self.current_page += 1
        self.load_pois()

    def go_previous(self, *args):
        self.current_page -= 1
        self.load_pois()

    def on_poi_select(self, poi):
        # Handle POI selection
        pass
