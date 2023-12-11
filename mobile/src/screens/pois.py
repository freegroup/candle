import os
from kivy.app import App
from screens.base_screen import BaseScreen
from kivy.uix.boxlayout import BoxLayout
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


    def on_pre_enter(self, *args):
        self.load_pois()
        self.ids.header.say = _("Übersicht Orte: Seite {} von {}").format(self.current_page+1, len(self.pages))
        super(Pois, self).on_pre_enter(*args)
  
  
    def load_pois(self):
        self.all_pois = PoiManager.get_all()

        self.pages = [self.all_pois[i:i + self.pois_per_page] for i in range(0, len(self.all_pois), self.pois_per_page)]

        if len(self.pages) == 0:
            say( _("Sie haben noch keine eigene Orte hinterlegt oder gespeichert.") )
            return
        
        if self.current_page >= len(self.pages):
            self.current_page = 0  # Reset to first page if out of range

        self.ids.poi_list.clear_widgets()
        for poi in self.pages[self.current_page]:
            self.ids.poi_list.add_widget(SayButton(text=poi.name, say=poi.name,  size_hint_y=1, action=lambda poi=poi: self.on_poi_select(poi)))

        # Fill up with placeholder Widgets if needed
        for i in range(self.pois_per_page - len(self.pages[self.current_page])):
            self.ids.poi_list.add_widget(BorderWidget(size_hint_y=1))

        if len(self.all_pois) > self.pois_per_page:
            self.add_navigation_buttons(len(self.pages))


    def add_navigation_buttons(self, total_pages):
        layout = BoxLayout(orientation='horizontal', size_hint_y=1, spacing=10)
  
        if self.current_page > 0:
            button = SayButton(text=_('<<'), say=_('Gehe zu Seite {} von {}').format(self.current_page, total_pages), action=self.go_previous)
            button.halign = 'left'
            layout.add_widget(button)
        else:
            layout.add_widget(BorderWidget(size_hint_y=1))

        print(f"current: {self.current_page} , len {total_pages}")
        if self.current_page < (total_pages-1):
            button = SayButton(text=_('>>'), say=_('Gehe zu Seite {} von {}').format(self.current_page+2, total_pages), action=self.go_next)
            button.halign = 'right'
            layout.add_widget(button)
        else:
            layout.add_widget(BorderWidget(size_hint_y=1))

        if self.current_page > 0 or self.current_page < total_pages - 1:
            self.ids.poi_list.add_widget(layout)


    def go_next(self, *args):
        self.current_page += 1
        self.load_pois()
        say(_("Seite {} von {}").format(self.current_page+1, len(self.pages)))
        

    def go_previous(self, *args):
        self.current_page -= 1
        self.load_pois()
        say(_("Seite {} von {}").format(self.current_page+1, len(self.pages)))
  
    def on_poi_select(self, poi):
        App.get_running_app().navigate_to_poi_details(poi)

