import 'dart:async';

import 'package:candle/models/location_address.dart' as model;
import 'package:candle/models/navigation_point.dart' as model;
import 'package:candle/models/route.dart' as model;
import 'package:candle/services/compass.dart';
import 'package:candle/services/geocoding_osm.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/screen_wake.dart';
import 'package:candle/utils/colors.dart';
import 'package:candle/utils/configuration.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/bold_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:vibration/vibration.dart';

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
  int lastVibratedIndex = -1;

  @override
  void initState() {
    super.initState();
    ScreenWakeService.keepOn(true);

    //var geo = GoogleMapsGeocodingService();
    var geo = OSMGeocodingService();
    _route = geo.getPedestrianRoute(
      widget.source,
      widget.target.latlng(),
    );

    _currentLocation = widget.source;
    _updateWaypoint(_currentLocation);

    _waypoint = model.NavigationPoint(coordinate: widget.target.latlng(), annotation: "");

    _listenToLocationChanges();

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        log.e(err);
      }).listen((compassEvent) async {
        if (mounted) {
          var needleHeading = -(((compassEvent.heading ?? 0) + 360) % 360).toInt();
          // Normalize the needle heading [0-360] range and avoid negative values
          needleHeading = (needleHeading + 360) % 360;

          var newDistance = calculateDistance(_currentLocation, _waypoint.latlng()).toInt();
          if (needleHeading != _currentHeadingDegrees) {
            setState(() {
              log.d("setState regarding compass changes....");
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
    _locationSubscription?.cancel();

    super.dispose();
  }

  void _listenToLocationChanges() {
    _locationSubscription = LocationService.instance.updates.handleError((dynamic err) {
      log.e(err);
    }).listen((currentLocation) async {
      if (currentLocation.latitude == null || currentLocation.longitude == null) {
        return;
      }
      _currentLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      _updateWaypoint(_currentLocation);
      log.d("Got location update: $_currentLocation");
    });
  }

  void _updateWaypoint(LatLng currentLocation) async {
    final route = await _route;
    final closestSegment = route!.findClosestSegment(_currentLocation);
    int currentCoordinateIndex = closestSegment['start']['index'];

    int nextCoordinateIndex = currentCoordinateIndex + 1;

    while (nextCoordinateIndex < route.points.length &&
        const Distance().as(
              LengthUnit.Meter,
              currentLocation,
              route.points[nextCoordinateIndex].latlng(),
            ) <
            kMinDistanceForNextWaypoint) {
      currentCoordinateIndex = nextCoordinateIndex;
      nextCoordinateIndex++;
    }

    if (currentCoordinateIndex > lastVibratedIndex) {
      // Vibrate and update lastVibratedIndex
      Vibration.vibrate(duration: 100); // Assuming you have a vibration function
      lastVibratedIndex = currentCoordinateIndex;

      if (currentCoordinateIndex < route.points.length - 1) {
        _waypoint = route.points[currentCoordinateIndex + 1];
        setState(() {});
      }
    }
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
            waypoint: _waypoint.latlng(),
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
  final LatLng waypoint;
  static google.BitmapDescriptor? customCircleIcon;

  const RouteMapWidget({
    super.key,
    required this.route,
    required this.heading,
    required this.currentLocation,
    required this.waypoint,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  google.GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    if (RouteMapWidget.customCircleIcon == null) {
      _loadCustomIcon(); // Load the icon only if it's null
    }
  }

  void _loadCustomIcon() async {
    RouteMapWidget.customCircleIcon = await google.BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 1),
      'assets/images/location_marker.png', // Path to your circle icon
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
          bearing: (360) - widget.heading.toDouble(),
          zoom: 17,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    log.d("Building map...");

    ThemeData theme = Theme.of(context);
    final google.Marker currentLocationMarker = google.Marker(
      markerId: const google.MarkerId('current_location'),
      position: google.LatLng(widget.currentLocation.latitude, widget.currentLocation.longitude),
      icon: RouteMapWidget.customCircleIcon ?? google.BitmapDescriptor.defaultMarker,
      anchor: const Offset(0.5, 0), // Set anchor to top center
    );

    Set<google.Circle> circles = {};
    // Create a circle for the waypoint
    circles.add(google.Circle(
      circleId: const google.CircleId('waypoint'),
      center: google.LatLng(widget.waypoint.latitude, widget.waypoint.longitude),
      radius: 10, // Adjust the size as needed
      fillColor: Colors.red.withOpacity(0.8),
      strokeColor: Colors.red,
      strokeWidth: 2,
    ));

    circles.addAll(widget.route.points.map((point) {
      return google.Circle(
        circleId: google.CircleId(point.toString()),
        center: google.LatLng(point.coordinate.latitude, point.coordinate.longitude),
        radius: 4,
        fillColor: point.type == model.NavigationPointType.syntetic
            ? theme.primaryColor.withOpacity(0.5)
            : darken(theme.primaryColor, 0.15),
        strokeWidth: 1,
        strokeColor: darken(theme.primaryColor, 0.15),
      );
    }).toSet());

    // Create a polyline for the route
    google.Polyline routePolyline = google.Polyline(
      polylineId: const google.PolylineId('route'),
      points: widget.route.points
          .map((point) => google.LatLng(
                point.coordinate.latitude,
                point.coordinate.longitude,
              ))
          .toList(),
      color: theme.primaryColor,
      width: 10,
    );

    return google.GoogleMap(
      onMapCreated: (google.GoogleMapController controller) {
        _mapController = controller;
        centerMapOnCurrentLocation(); // Ensure map is centered on current location with correct heading
        controller.setMapStyle(kMapStyle);
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
