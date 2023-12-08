from math import degrees
from plyer import spatialorientation
from kivy.clock import Clock

class CompassManager:
    _needle_angle = 0
    _compass_enabled = False

    @classmethod
    def start(cls):
        """Starts the compass tracking."""
        try:
            spatialorientation.enable_listener()
            Clock.schedule_interval(cls.update_compass, 1 / 20)
            cls._compass_enabled = True
        except Exception as e:
            print(e)
            print("Compass not implemented on this platform")

    @classmethod
    def stop(cls):
        """Stops the compass tracking."""
        try:
            if cls._compass_enabled:
                spatialorientation.disable_listener()
                Clock.unschedule(cls.update_compass)
                cls._compass_enabled = False
        except Exception as e:
            print(e)
            print("Compass not available on this platform")

    @classmethod
    def update_compass(cls, dt):
        """Updates the compass reading."""
        try:
            orientation = spatialorientation.orientation
            if orientation:
                azimuth, _, _ = orientation
                if azimuth:
                    azimuth_deg = degrees(azimuth)
                    azimuth_deg = azimuth_deg % 360
                    cls._needle_angle = azimuth_deg
            else:
                print("Unable to get Compass data")
        except NotImplementedError:
            print("Compass is not implemented for your platform")

    @classmethod
    def get_angle(cls):
        """Returns the current compass angle."""
        return cls._needle_angle
