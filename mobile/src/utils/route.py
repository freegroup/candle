import os
import math
import random

from typing import List

from kivy.app import App

import gpxpy
import gpxpy.gpx
from geopy.distance import geodesic
from shapely.geometry import Point, LineString


from utils.poi import Poi, PoiType

GPX_ROUTE_SUBDIR="gpx_routes"


class Route:

    @classmethod
    def load_gpx(cls, filename):
        data_directory = App.get_running_app().user_data_dir
        file_path = os.path.join(data_directory,GPX_ROUTE_SUBDIR, filename)

        with open(file_path, 'r') as gpx_file:
            gpx = gpxpy.parse(gpx_file)

        pois = []
        for track in gpx.tracks:
            for segment in track.segments:
                for point in segment.points:
                    poi = Poi(lat=point.latitude, lon=point.longitude, name=point.name, type=PoiType.ROUTE)
                    pois.append(poi)
        return Route(name=filename, points=pois)



    def __init__(self, name, points: List[Poi]):
        self.name = name
        self.points = points



    def dump_gpx(self):
        data_directory = App.get_running_app().user_data_dir
        gpx_directory = os.path.join(data_directory, GPX_ROUTE_SUBDIR)
        file_path = os.path.join(gpx_directory, self.name)

        # Ensure the directory exists
        os.makedirs(gpx_directory, exist_ok=True)

        gpx = gpxpy.gpx.GPX()

        # Create track
        gpx_track = gpxpy.gpx.GPXTrack(name=self.name)
        gpx.tracks.append(gpx_track)

        # Create segment
        gpx_segment = gpxpy.gpx.GPXTrackSegment()
        gpx_track.segments.append(gpx_segment)

        # Add points to segment
        for poi in self.points:
            if poi.type == PoiType.ROUTE:
                gpx_point = gpxpy.gpx.GPXTrackPoint(poi.lat, poi.lon, name=poi.name)
                gpx_segment.points.append(gpx_point)

        xml = gpx.to_xml()
        with open(file_path, 'w') as gpx_file:
            gpx_file.write(xml)

        print(f"GPX data written to {file_path}")


    def calculate_waypoint_route(self) -> Route:
        min_segment_length = 15
        distance_to_insert = 10

        modified_points = []

        for i, current_poi in enumerate(self.points):
            prev_poi, next_poi = self.find_adjacent_poi(current_poi)

            # Add extra previous point
            if prev_poi and self.is_special_coordinate(current_poi):
                prev_segment_length = geodesic((current_poi.lat, current_poi.lon), (prev_poi.lat, prev_poi.lon)).meters
                if prev_segment_length > min_segment_length:
                    # Calculate and insert extra previous point
                    extra_prev_poi = self.interpolate_poi(current_poi, prev_poi, distance_to_insert)
                    modified_points.append(extra_prev_poi)

            # Add the current point
            modified_points.append(current_poi)

            # Add extra next point
            if next_poi and self.is_special_coordinate(current_poi):
                next_segment_length = geodesic((current_poi.lat, current_poi.lon), (next_poi.lat, next_poi.lon)).meters
                if next_segment_length > min_segment_length:
                    # Calculate and insert extra next point
                    extra_next_poi = self.interpolate_poi(current_poi, next_poi, distance_to_insert)
                    modified_points.append(extra_next_poi)

        return Route(name = self.name, points=modified_points)


    def find_adjacent_poi(self, poi) -> (Poi, Poi):
        """Find adjacent points (previous and next) for a given Poi in the route."""
        try:
            current_index = self.points.index(poi)
            prev_poi = self.points[current_index - 1] if current_index > 0 else None
            next_poi = self.points[current_index + 1] if current_index < len(self.points) - 1 else None
            return prev_poi, next_poi
        except ValueError:
            # Current poi not in self.points
            return None, None


    def calculate_angle(self, p2):
        """Calculates the angle of p2. p2 is in between of p1 and p3 which are determined from the route waypoints.
        """
        p1, p3 = self.find_adjacent_poi(p2)
        # Check if all points are given
        if not p1 or not p2 or not p3:
            return 0

        # Calculate distances between the points
        a = geodesic((p2.lat, p2.lon), (p3.lat, p3.lon)).meters
        b = geodesic((p1.lat, p1.lon), (p3.lat, p3.lon)).meters
        c = geodesic((p1.lat, p1.lon), (p2.lat, p2.lon)).meters

        # Apply the Law of Cosines to find the angle at p2
        # Clamp cos_angle to the valid range [-1, 1] to avoid math domain error
        cos_angle = max(-1, min(1, (a**2 + c**2 - b**2) / (2 * a * c)))
        angle = math.acos(cos_angle) * (180 / math.pi)

        return angle


    def find_closest_segment(self, poi):
        min_distance = float('inf')
        closest_segment_start_index = None

        for i in range(len(self.points) - 1):
            start_coord = self.points[i]
            end_coord = self.points[i + 1]

            # Create a line segment and a point
            line = LineString([(start_coord.lon, start_coord.lat), (end_coord.lon, end_coord.lat)])
            point = Point(poi.lon, poi.lat)

            # Use Shapely to compute the distance
            current_distance = line.distance(point)

            if current_distance < min_distance:
                min_distance = current_distance
                closest_segment_start_index = i

        if closest_segment_start_index is None:
            raise ValueError("Could not find closest segment.")

        closest_segment_end_index = closest_segment_start_index + 1
        closest_segment = {
            "start": {
                "index": closest_segment_start_index,
                "coord": self.points[closest_segment_start_index]
            },
            "end": {
                "index": closest_segment_end_index,
                "coord": self.points[closest_segment_end_index]
            },
            "distance": min_distance
        }

        return closest_segment


    def get_random_point_near_route(self) -> Poi:
        if not self.points:
            raise ValueError("The route has no points.")

        random_index = random.randint(0, len(self.points) - 1)  # Random index in the route
        random_radius = 2 + random.random() * 18  # Radius between 2 and 20 meters
        random_bearing = random.random() * 360  # Random bearing in degrees

        original_point = self.points[random_index]
        # Calculate the new point using geodesic distance and random bearing
        destination = geodesic(kilometers=random_radius / 1000).destination((original_point.lat, original_point.lon), random_bearing)

        return Poi(lat=destination.latitude,lon=destination.longitude)
    
    
    def is_special_coordinate(self, poi) -> bool:
        """Decides whenever the coordinate is special. Special in the sense of pedestrian navigation. In this case the point needs
        some vertex in front and behind of them.
        """
        angle = self.calculate_angle(poi)
        return 60 <= angle <= 120


    def interpolate_poi(self, from_poi, to_poi, distance) -> Poi:
        # Logic to calculate the position of the extra point
        # This might involve bearing calculation and distance offset
        # Placeholder for the actual implementation
        lat_offset = (to_poi.lat - from_poi.lat) * (distance / geodesic((from_poi.lat, from_poi.lon), (to_poi.lat, to_poi.lon)).meters)
        lon_offset = (to_poi.lon - from_poi.lon) * (distance / geodesic((from_poi.lat, from_poi.lon), (to_poi.lat, to_poi.lon)).meters)
        return Poi(lat=from_poi.lat + lat_offset, lon=from_poi.lon + lon_offset, poi_type=PoiType.SYNTHETIC)
