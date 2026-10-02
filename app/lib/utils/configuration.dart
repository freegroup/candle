const String kAppStoreLink = 'https://apps.apple.com/de/app/candle-navigation-app/id6478289375';
const String kPlayStoreLink = 'https://play.google.com/store/apps/details?id=de.freegroup.candle.app';

// OpenStreetMap services (Overpass, Nominatim) and Wikipedia reject requests
// with the default "Dart/x.y (dart:io)" User-Agent.
const Map<String, String> kHttpHeaders = {
  'User-Agent': 'Candle/1.4 (de.freegroup.candle; +https://github.com/freegroup/candle)',
};

const int kMinDistanceForNextWaypoint = 5;
const int kMinDistanceForLocationNoteAnnouncement = 8;
const int kPoiRadiusInMeter = 2000;
const List<int> kSnapPoints = [0, 45, 90, 135, 180, 225, 270, 315];
const int kSnapRange = 10; // ±10° range for snap points

const String kMapStyle = '''
[
  {
    "featureType": "administrative",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "landscape",
    "stylers": [
      {
        "color": "#090906"
      },
      {
        "visibility": "on"
      }
    ]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffeb3b"
      },
      {
        "saturation": 30
      },
      {
        "lightness": -85
      },
      {
        "visibility": "on"
      },
      {
        "weight": 0.5
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "water",
    "stylers": [
      {
        "color": "#39392d"
      },
      {
        "visibility": "on"
      }
    ]
  }
]
  ''';
