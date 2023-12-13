import os
import openrouteservice

from kivy.app import App
from kivy.lang import Builder
from kivy.clock import Clock
from kivy_garden.mapview import MapMarker

from screens.base_screen import BaseScreen
from utils.i18n import _
from utils.poi import Poi
from utils.location import LocationManager
from controls.line_map_layer import LineMapLayer


OPENSTREETMAP_API_KEY= os.getenv('OPENSTREETMAP_API_KEY')

dir_path = os.path.dirname(os.path.realpath(__file__))

kv_file_path = os.path.join(dir_path, 'poi_routing.kv')
pin_path = os.path.join(dir_path, 'pin.png') 

Builder.load_file(kv_file_path)

class PoiRouting(BaseScreen):
    poi = None  # Attribute to hold the passed POI


    def on_enter(self):
        print("on_enter")
        current = LocationManager.get_location()
        Clock.schedule_once(lambda dx: self._calculate_walking_route(current.lat, current.lon, self.poi.lat, self.poi.lon), 0)

        def callback(dt):
            print(current)
            mapview = self.ids.mapview
            mapview.center_on( current.lat, current.lon)

        # Schedule the callback function to run in a separate thread with a slight delay
        Clock.schedule_once(callback, 5)  # Adjust the delay as needed


    def back(self):
        App.get_running_app().navigate_to_pois("right")


    def navigation_pause(self):
        print("navigation_pause")


    def navigation_show(self):
        print("navigation_show")


    def navigation_change(self):
        print("navigation_change")


    def navigation_stop(self):
        print("navigation_stop")

    def _calculate_walking_route(self, lat1, lon1, lat2, lon2):
        client = openrouteservice.Client(key=OPENSTREETMAP_API_KEY)  # Replace with your OpenRouteService API key
        
        coords = ((lon1, lat1), (lon2, lat2))
        routes = client.directions(coords, profile='foot-walking', format='geojson')
        
        self.route_latlons = [
            Poi(lat=coord[1], lon=coord[0])
            for coord in routes['features'][0]['geometry']['coordinates']
        ]

        # Assuming you have a method in MapView to add a line
        mapview = self.ids.mapview

        points = []
        for poi in self.route_latlons:
            # Convert latitude and longitude to x and y for the MapView
            points.append([poi.lat, poi.lon])

        # Add routes
        lml1 = LineMapLayer(coordinates=points, color=[1, 0, 0, 1])
        mapview.add_layer(lml1, mode="scatter")

        marker = MapMarker(lat=lat1, lon=lon1, source=pin_path)
        mapview.add_marker(marker)

        marker = MapMarker(lat=lat2, lon=lon2, source=pin_path)
        mapview.add_marker(marker)


    def _create_gpx(self, pois):
        gpx_template = '''<?xml version="1.0" encoding="UTF-8"?>
    <gpx version="1.1" creator="YourAppName">
        <trk><name>Your Route Name</name><trkseg>\n'''
        for poi in pois:
            gpx_template += f'<trkpt lat="{poi.lat}" lon="{poi.lon}"><name>{poi.name}</name></trkpt>\n'
        gpx_template += '''    </trkseg></trk>
    </gpx>'''
        return gpx_template
