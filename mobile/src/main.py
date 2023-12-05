from kivy.app import App
from kivy.uix.screenmanager import ScreenManager

from screens.main import Main
from screens.record import Record

class CandleApp(App):


    def build(self):
        self.sm = ScreenManager()
        self.sm.add_widget(Main(name='main'))
        self.sm.add_widget(Record(name='record'))
        
        self.main()

        return self.sm
    
    def terminate(self):
        self.stop()
        
    def main(self):
        self.sm.current="main"
        
    def record(self):
        self.sm.current="record"


if __name__ == '__main__':
    CandleApp().run()

