import gpxpy
import gpxpy.gpx
import os
from kivy.app import App

class Poi:
    def __init__(self, lon, lat, name, desc):
        self.lon = lon
        self.lat = lat
        self.name = name
        self.desc = desc


class PoiManager:
    def _ensure_file(filename="pois.gpx"):
        # Get user data directory from Kivy App
        data_directory = App.get_running_app().user_data_dir
        file_path = os.path.join(data_directory, filename)

        # Create the GPX file if it doesn't exist
        if not os.path.exists(file_path):
            gpx = gpxpy.gpx.GPX()
            with open(file_path, 'w') as file:
                file.write(gpx.to_xml())

        # Return the file path
        print(file_path)
        return file_path

    @staticmethod
    def get_all():
        file_path = PoiManager._ensure_file()
        with open(file_path, 'r') as file:
            gpx = gpxpy.parse(file)
        return [Poi(lon=wpt.longitude, lat=wpt.latitude, name=wpt.name, desc=wpt.comment) for wpt in gpx.waypoints]


    @staticmethod
    def add(poi):
        file_path = PoiManager._ensure_file()
        with open(file_path, 'r') as file:
            gpx = gpxpy.parse(file)

        new_wpt = gpxpy.gpx.GPXWaypoint(latitude=poi.lat, longitude=poi.lon, name=poi.name, comment=poi.desc)
        gpx.waypoints.append(new_wpt)

        with open(file_path, 'w') as file:
            file.write(gpx.to_xml())


    @staticmethod
    def delete(poi):
        file_path = PoiManager._ensure_file()
        with open(file_path, 'r') as file:
            gpx = gpxpy.parse(file)

        gpx.waypoints = [wpt for wpt in gpx.waypoints if wpt.name != poi.name]

        with open(file_path, 'w') as file:
            file.write(gpx.to_xml())