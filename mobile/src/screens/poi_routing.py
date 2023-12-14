import os
import openrouteservice

from kivy.app import App
from kivy.lang import Builder
from kivy.clock import Clock
from kivy_garden.mapview import MapMarker

from geopy.distance import geodesic

from screens.base_screen import BaseScreen
from utils.i18n import _
from utils.poi import Poi
from utils.route import Route
from utils.location import LocationManager
from controls.line_map_layer import LineMapLayer


OPENSTREETMAP_API_KEY= os.getenv('OPENSTREETMAP_API_KEY')

dir_path = os.path.dirname(os.path.realpath(__file__))

kv_file_path = os.path.join(dir_path, 'poi_routing.kv')
pin_path = os.path.join(dir_path, 'pin.png') 
pin_t_path = os.path.join(dir_path, 'pin_t.png') 

Builder.load_file(kv_file_path)

class PoiRouting(BaseScreen):
    poi = None  # Attribute to hold the passed POI
    current_location_marker = None
    next_location_marker = None

    last_target_poi = None
    last_vibrated_index = -1

    route = None

    def on_enter(self):
        print("on_enter")
        current = LocationManager.get_location()

        self.current_location_marker = MapMarker(lat=current.lat, lon=current.lon, source=pin_path)
        mapview = self.ids.mapview
        mapview.add_marker(self.current_location_marker)

        self.next_location_marker = MapMarker(lat=current.lat, lon=current.lon, source=pin_t_path)
        mapview = self.ids.mapview
        mapview.add_marker(self.next_location_marker)

        Clock.schedule_once(lambda dx: self._calculate_walking_route(current.lat, current.lon, self.poi.lat, self.poi.lon), 0)

        # Schedule the callback function to update the current location
        Clock.schedule_interval(self.update_navigation_target, 1)  # Check every 5 seconds


    def update_navigation_target(self, dt):
        current_location = LocationManager.get_location()
        if current_location:
            self.update_current_location(current_location)
            self.update_target_poi(current_location)


    def update_current_location(self, *args):
        """Update the position of the current location marker."""
        current = LocationManager.get_location()
        if current and self.current_location_marker:
            self.current_location_marker.lat = current.lat
            self.current_location_marker.lon = current.lon
            mapview = self.ids.mapview
            mapview.center_on(current.lat, current.lon) 


    def update_target_poi(self, current_location):
        # Find the closest segment
        if self.route:
            closest_segment = self.route.find_closest_segment(current_location)
            current_coordinate_index = closest_segment["start"]["index"]

            min_distance = 5  # Minimum distance in meters
            next_coordinate_index = current_coordinate_index + 1

            while next_coordinate_index < len(self.route.points) and \
                geodesic((current_location.lat, current_location.lon),
                        (self.route.points[next_coordinate_index].lat, 
                            self.route.points[next_coordinate_index].lon)).meters < min_distance:
                current_coordinate_index = next_coordinate_index
                next_coordinate_index += 1

            if current_coordinate_index > self.last_vibrated_index:
                self.vibrate()
                self.last_vibrated_index = current_coordinate_index
                if current_coordinate_index < len(self.route.points) - 1:
                    self.set_next_marker(self.route.points[current_coordinate_index + 1])
                else:
                    self.set_next_marker(None)


    def set_next_marker(self, poi):
        if poi and self.current_location_marker:
            self.next_location_marker.lat = poi.lat
            self.next_location_marker.lon = poi.lon


    def back(self):
        App.get_running_app().navigate_to_poi_details(self.poi, "right")


    def navigation_pause(self):
        print("navigation_pause")


    def navigation_details(self):
        print("navigation_details")


    def navigation_change(self):
        print("navigation_change")


    def navigation_stop(self):
        print("navigation_stop")


    def target_poi_has_changed(self, new_target_poi):
        # Check if the target POI has changed
        return new_target_poi != self.last_target_poi


    def _calculate_walking_route(self, lat1, lon1, lat2, lon2):
        client = openrouteservice.Client(key=OPENSTREETMAP_API_KEY)  # Replace with your OpenRouteService API key
        
        coords = ((lon1, lat1), (lon2, lat2))
        self.routes = client.directions(coords, profile='foot-walking', format='geojson')
        
        self.route_latlons = [
            Poi(lat=coord[1], lon=coord[0])
            for coord in self.routes['features'][0]['geometry']['coordinates']
        ]
        self.route = Route("current", self.route_latlons)
        self.route = self.route.calculate_waypoint_route()
        
        self.route.dump_gpx()

        # Assuming you have a method in MapView to add a line
        mapview = self.ids.mapview

        # Add routes
        lml1 = LineMapLayer(route=self.route, color=[1, 0, 0, 1])
        mapview.add_layer(lml1, mode="scatter")

        #LocationManager.start_simulate_route(self.route)
       