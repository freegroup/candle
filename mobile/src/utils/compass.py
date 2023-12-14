from collections import deque

from math import degrees
from plyer import spatialorientation
from kivy.clock import Clock

class CompassManager:
    _needle_angle = 0
    _compass_enabled = False
    _angles = deque(maxlen=10)  # Store recent readings with a maximum window size of 10

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
        except NotImplementedError as e:
            print(e)
            print("Compass not available on this platform")
        except Exception as e:
            print(e)


    @classmethod
    def update_compass(cls, dt):
        try:
            orientation = spatialorientation.orientation
            if orientation:
                azimuth, _, _ = orientation
                if azimuth:
                    azimuth_deg = degrees(azimuth) % 360
                    cls._angles.append(azimuth_deg)
                    cls._needle_angle = cls.calculate_median()
            else:
                print("Unable to get Compass data")
        except NotImplementedError:
            print("Compass is not implemented for your platform")
        except Exception as e:
            print(e)


    @classmethod
    def calculate_median(cls):
        """
        Calculates the median of the angles in the window.
        """
        if not cls._angles:
            return 0
        sorted_angles = sorted(cls._angles)
        mid = len(sorted_angles) // 2
        if len(sorted_angles) % 2 == 0:  # Even number of elements
            return (sorted_angles[mid - 1] + sorted_angles[mid]) / 2.0
        else:  # Odd number of elements
            return sorted_angles[mid]

    @classmethod
    def get_angle(cls):
        """Returns the current compass angle."""
        return cls._needle_angle
    
