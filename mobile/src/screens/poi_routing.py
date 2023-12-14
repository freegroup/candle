import os

from kivy.app import App
from kivy.lang import Builder
from kivy.clock import Clock
from kivy_garden.mapview import MapMarker

from geopy.distance import geodesic

from screens.base_screen import BaseScreen
from utils.i18n import _
from utils.route import Route
from utils.location import LocationManager
from utils.compass import CompassManager
from utils.haptic_compass import HapticCompass
from controls.line_map_layer import LineMapLayer
from utils.gps_utils import calculate_north_bearing


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
        mapview = self.ids.mapview

        self.current_location_marker = MapMarker(lat=current.lat, lon=current.lon, source=pin_path)
        mapview.add_marker(self.current_location_marker)

        self.next_location_marker = MapMarker(lat=current.lat, lon=current.lon, source=pin_t_path)
        mapview.add_marker(self.next_location_marker)

        Clock.schedule_once(lambda dx: self._calculate_walking_route(current, self.poi), 0)

        # Schedule the callback function to update the current location
        Clock.schedule_interval(self.update_navigation_target, 1)  # Check every 5 seconds


    def on_leave(self):
        last_target_poi = None
        last_vibrated_index = None
        mapview = self.ids.mapview
        Clock.unschedule(self.update_navigation_target)
        mapview.remove_marker(self.current_location_marker)
        mapview.remove_marker(self.next_location_marker)



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
                    next_poi = self.route.points[current_coordinate_index + 1]
                    self.set_next_marker(next_poi)
                    poi_heading = calculate_north_bearing(LocationManager.get_location(), next_poi)
                    device_heading = CompassManager.get_angle()
                    needle_angle = (poi_heading - device_heading ) % 360
                    HapticCompass.set_angle(needle_angle)
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


    def _calculate_walking_route(self, poi_from, poi_target):
        self.route = Route.calculate_route(poi_from=poi_from, poi_target=poi_target).calculate_waypoint_route()
        self.route.dump_gpx()

        lml1 = LineMapLayer(route=self.route, color=[1, 0, 0, 1])
        self.ids.mapview.add_layer(lml1, mode="scatter")

        LocationManager.start_simulate_route(self.route)
       