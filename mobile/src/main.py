from kivy.app import App
from kivy.uix.screenmanager import ScreenManager

from screens.main_screen import MainScreen
from screens.recording_screen import RecordingScreen


class CandleApp(App):
    
    def custom_action(self):
        pass

    def build(self):
        self.sm = ScreenManager()
        self.sm.add_widget(MainScreen(name='main'))
        self.sm.add_widget(RecordingScreen(name='recording'))

        self.set_screen('main')

        return self.sm

    def set_screen(self, name):
        self.sm.current = name
        
if __name__ == '__main__':
    CandleApp().run()

