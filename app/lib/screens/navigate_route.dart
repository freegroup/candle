import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';

import 'package:candle/services/geocoding_google.dart';
import 'package:candle/services/geocoding_osm.dart';
import 'package:candle/services/screen_wake.dart';
import 'package:candle/services/compass.dart';
import 'package:candle/services/location.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:candle/models/location_address.dart' as model;
import 'package:candle/models/navigation_point.dart' as model;
import 'package:candle/models/route.dart' as model;

class NavigateRouteScreen extends StatefulWidget {
  final LatLng source;
  final model.LocationAddress target;

  const NavigateRouteScreen({super.key, required this.source, required this.target});

  @override
  State<NavigateRouteScreen> createState() => _ScreenState();
}

class _ScreenState extends State<NavigateRouteScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<LocationData>? _locationSubscription;

  int _currentHeadingDegrees = 0;
  int _currentDistanceToWaypoint = 0;
  late model.NavigationPoint _waypoint;
  late LatLng _currentLocation;
  late Future<model.Route?> _route;

  @override
  void initState() {
    super.initState();
    ScreenWakeService.keepOn(true);

    _currentLocation = widget.source;

    //var geo = GoogleMapsGeocodingService();
    var geo = OSMGeocodingService();
    _route = geo.getPedestrianRoute(
      widget.source,
      widget.target.latlng(),
    );

    _waypoint = model.NavigationPoint(coordinate: widget.target.latlng(), annotation: "");

    _listenToLocationChanges();

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        print(err);
      }).listen((compassEvent) async {
        if (mounted) {
          var poiHeading = calculateNorthBearing(_currentLocation, _waypoint.latlng());
          var deviceHeading = (((compassEvent.heading ?? 0) + 360) % 360).toInt();
          var needleHeading = -(deviceHeading - poiHeading);
          // Normalize the needle heading [0-360] range and avoid negative values
          needleHeading = (needleHeading + 450) % 360;

          var newDistance = calculateDistance(_currentLocation, _waypoint.latlng()).toInt();
          if (needleHeading != _currentHeadingDegrees) {
            setState(() {
              print("setState regarding compass changes....");
              _currentHeadingDegrees = needleHeading;
              _currentDistanceToWaypoint = newDistance;
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    ScreenWakeService.keepOn(false);
    _compassSubscription?.cancel();
    _locationSubscription?.cancel(); // Cancel the location subscription

    super.dispose();
  }

  void _listenToLocationChanges() {
    _locationSubscription = LocationService.instance.updates.handleError((dynamic err) {
      print(err);
    }).listen((currentLocation) async {
      if (currentLocation.latitude == null || currentLocation.longitude == null) {
        return;
      }
      _currentLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      print("Got location update: $_currentLocation");
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.compass_dialog),
        talkback: l10n.compass_poi_dialog_t("Wegpunkt"),
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              flex: 5, // 2/3 of the screen for the compass
              child: _buildRouteMap(),
            ),
            Expanded(child: Container()),
            Container(
              width: double.infinity,
              child: Semantics(
                label: l10n.location_distance_t("wegpunkt", _currentDistanceToWaypoint),
                child: Align(
                  alignment: Alignment.center,
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Text("Wegpunkt", style: theme.textTheme.displayMedium),
                        Text(
                          '${_currentDistanceToWaypoint.toStringAsFixed(0)} Meter',
                          style: theme.textTheme.displaySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: Container()),
            BoldIconButton(
                talkback: l10n.button_close_t,
                buttonWidth: MediaQuery.of(context).size.width / 5,
                icons: Icons.close,
                onTab: () {
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }

  // Separate method to build the map, isolated from other state changes.
  Widget _buildRouteMap() {
    return FutureBuilder<model.Route?>(
      future: _route,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Consider logging the error or showing a more informative message
          return Center(child: Text('Error fetching route: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data != null) {
          return RouteMapWidget(
            route: snapshot.data!,
            heading: _currentHeadingDegrees.toDouble(),
            currentLocation: _currentLocation,
          );
        } else {
          return const Center(child: Text('No route found'));
        }
      },
    );
  }
}

class RouteMapWidget extends StatefulWidget {
  final model.Route route;
  final double heading;
  final LatLng currentLocation;

  final String mapStyle = '''
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
  const RouteMapWidget({
    super.key,
    required this.route,
    required this.heading,
    required this.currentLocation,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  google.GoogleMapController? _mapController;
  google.BitmapDescriptor? customCircleIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomIcon();
  }

  void _loadCustomIcon() async {
    customCircleIcon = await google.BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/icons/location_marker.png', // Path to your circle icon
    );
  }

  @override
  void didUpdateWidget(RouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.heading != oldWidget.heading ||
        widget.currentLocation != oldWidget.currentLocation) {
      centerMapOnCurrentLocation();
    }
  }

  void centerMapOnCurrentLocation() {
    _mapController?.moveCamera(
      google.CameraUpdate.newCameraPosition(
        google.CameraPosition(
          target: google.LatLng(
            widget.currentLocation.latitude,
            widget.currentLocation.longitude,
          ),
          bearing: (360 + 90 + 180) - widget.heading.toDouble(),
          zoom: 17,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Building map...");

    ThemeData theme = Theme.of(context);
    final google.Marker currentLocationMarker = google.Marker(
      markerId: google.MarkerId('current_location'),
      position: google.LatLng(widget.currentLocation.latitude, widget.currentLocation.longitude),
      icon: customCircleIcon ?? google.BitmapDescriptor.defaultMarker,
    );

    Set<google.Circle> circles = widget.route.points.map((point) {
      return google.Circle(
        circleId: google.CircleId(point.toString()),
        center: google.LatLng(point.coordinate.latitude, point.coordinate.longitude),
        radius: 7,
        fillColor: theme.primaryColor.withOpacity(0.5),
        strokeWidth: 2,
        strokeColor: theme.primaryColor,
      );
    }).toSet();

    // Create a polyline for the route
    google.Polyline routePolyline = google.Polyline(
      polylineId: const google.PolylineId('route'),
      points: widget.route.points
          .map((point) => google.LatLng(point.coordinate.latitude, point.coordinate.longitude))
          .toList(),
      color: theme.primaryColor,
      width: 10,
    );

    return google.GoogleMap(
      onMapCreated: (google.GoogleMapController controller) {
        _mapController = controller;
        centerMapOnCurrentLocation(); // Ensure map is centered on current location with correct heading
        controller.setMapStyle(widget.mapStyle);
      },
      initialCameraPosition: google.CameraPosition(
        target: google.LatLng(
          widget.currentLocation.latitude,
          widget.currentLocation.longitude,
        ),
        zoom: 17.0,
        bearing: widget.heading,
      ),
      markers: {currentLocationMarker},
      polylines: {routePolyline},
      circles: circles,
      scrollGesturesEnabled: false, // Disable scroll gestures
      zoomGesturesEnabled: false, // Disable zoom gestures
      tiltGesturesEnabled: false, // Disable tilt gestures
      rotateGesturesEnabled: false, // Disable rotate gestures
      zoomControlsEnabled: false,
      compassEnabled: false,
    );
  }
}
