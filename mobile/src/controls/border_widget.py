
import os

from kivy.uix.widget import Widget
from kivy.lang import Builder

# Load the KV file for this module
Builder.load_file(os.path.join(os.path.dirname(__file__), 'border_widget.kv'))

class BorderWidget(Widget):
    pass

