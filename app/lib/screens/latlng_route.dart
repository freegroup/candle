import 'dart:async';

import 'package:candle/models/navigation_point.dart' as model;
import 'package:candle/models/route.dart' as model;
import 'package:candle/services/compass.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/router.dart';
import 'package:candle/services/screen_wake.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/utils/configuration.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:candle/widgets/route_map_osm.dart';
import 'package:candle/widgets/target_reached.dart';
import 'package:candle/widgets/turn_by_turn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

class LatLngRouteScreen extends StatefulWidget {
  final LatLng source;
  final LatLng target;

  const LatLngRouteScreen({super.key, required this.source, required this.target});

  @override
  State<LatLngRouteScreen> createState() => _ScreenState();
}

class _ScreenState extends State<LatLngRouteScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<LocationData>? _locationSubscription;

  late Future<model.Route?> _route;

  int _currentMapRotation = 0;
  int _currentWaypointHeading = 0;
  int _distanceToTurnByTurnWaypoint = 0;

  int _distanceToTarget = 0;
  // it is a oneTime toggle. Once the target is reached, it never gets back to "false"
  bool targetReached = false;

  // the current location of the user given by the GPS signal
  late LatLng _currentLocation;
  // this is the waypoint where the compas is pointing
  model.NavigationPoint? _currentHeadingWaypoint;
  // this is the next routing waypoint for the turn-by-turn instruction
  model.NavigationPoint? _currentTurnByTurnWaypoint;
  // this is the successor routing waypoint for the turn-by-turn instruction
  model.NavigationPoint? _nextTurnByTurnWaypoint;

  // vibration handlnig
  //
  int lastVibratedIndex = -1;
  bool _wasAligned = false;
  int _needleHeading = 0;

  @override
  void initState() {
    super.initState();
    ScreenWakeService.keepOn(true);

    _route = _calculateRoute(widget.source, widget.target);
    _currentLocation = widget.source;
    _updateWaypoints(_currentLocation);
    _listenToLocationChanges();

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        log.e(err);
      }).listen((compassEvent) async {
        if (mounted && _currentHeadingWaypoint != null) {
          var route = await _route;
          if (route == null) return;
          var waypointHeading =
              calculateNorthBearing(_currentLocation, _currentHeadingWaypoint!.latlng());
          var deviceHeading = (((compassEvent.heading ?? 0) + 360) % 360).toInt();
          var needleHeading = -(deviceHeading - waypointHeading);
          bool currentlyAligned = _isAligned(deviceHeading, waypointHeading);

          if (currentlyAligned != _wasAligned) {
            if (currentlyAligned) {
              Vibration.vibrate(duration: 100, repeat: 2);
            } else {
              Vibration.vibrate(duration: 500);
            }
            _wasAligned = currentlyAligned;
          }

          var newDistance =
              calculateDistance(_currentLocation, _currentTurnByTurnWaypoint!.latlng()).toInt();
          var resumeDistance =
              route.calculateResumingLengthFromWaypoint(_currentHeadingWaypoint!).toInt() +
                  newDistance;

          if (mounted &&
              (deviceHeading != _currentMapRotation ||
                  newDistance != _distanceToTurnByTurnWaypoint ||
                  resumeDistance != _distanceToTarget)) {
            setState(() {
              _currentMapRotation = deviceHeading;
              _currentWaypointHeading = waypointHeading;
              _distanceToTurnByTurnWaypoint = newDistance;
              _distanceToTarget = resumeDistance;
              _needleHeading = needleHeading;
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    ScreenWakeService.keepOn(false);
    _compassSubscription?.cancel();
    _locationSubscription?.cancel();
  }

  Future<model.Route?> _calculateRoute(LatLng start, LatLng target) async {
    try {
      var geo = Provider.of<RoutingProvider>(context, listen: false).service;
      lastVibratedIndex = -1;
      return await geo.getPedestrianRoute(start, target);
    } catch (e) {
      log.e("Error fetching route: $e");
      return null; // Or handle the error as needed
    }
  }

  bool _isAligned(int mapRotation, waypointHeading) {
    var diff = mapRotation - waypointHeading;
    return (diff.abs() <= 8) || (diff.abs() >= 352);
  }

  void _listenToLocationChanges() {
    _locationSubscription = LocationService.instance.updates.handleError((dynamic err) {
      log.e(err);
    }).listen((newLocation) async {
      if (newLocation.latitude == null || newLocation.longitude == null) {
        return;
      }
      _currentLocation = LatLng(newLocation.latitude!, newLocation.longitude!);
      _updateWaypoints(_currentLocation);
    });
  }

  void _updateWaypoints(LatLng location) async {
    print(targetReached);
    if (targetReached == true) {
      return;
    }

    final route = await _route;
    if (route == null) {
      _route = _calculateRoute(location, widget.target);
      // try to find a wayoint in the next iteration
      return;
    }

    final closestSegment = route.findClosestSegment(location);

    // If the closest segment far away from my current location, we calculate
    // a new route. Because the pedestrian is to far from the next segment of the route.
    //
    var distance = closestSegment["distance"];
    if (distance > 15) {
      log.d("Closest Segment is to far ($distance)- recalculate route....");
      _route = _calculateRoute(location, widget.target);
      // try to find a wayoint in the next iteration
      return;
    }

    int startCoordinateIndex = closestSegment['start']['index'];
    int endCoordinateIndex = closestSegment['end']['index'];

    int nextCoordinateIndex = endCoordinateIndex;
    log.d("Found closest startCoordinateIndex: $startCoordinateIndex");

    while (nextCoordinateIndex < route.points.length &&
        const Distance().as(
              LengthUnit.Meter,
              location,
              route.points[nextCoordinateIndex].latlng(),
            ) <
            kMinDistanceForNextWaypoint) {
      startCoordinateIndex = nextCoordinateIndex;
      nextCoordinateIndex++;
      log.d(
          "Coordinate index changed because of closer segment startCoordinateIndex:$startCoordinateIndex");
    }

    if (startCoordinateIndex > lastVibratedIndex) {
      // Vibrate and update lastVibratedIndex
      Vibration.vibrate(duration: 100); // Assuming you have a vibration function
      lastVibratedIndex = startCoordinateIndex;

      if (startCoordinateIndex < route.points.length - 1) {
        // index the next point of the first segment
        startCoordinateIndex++;
        _currentHeadingWaypoint = route.points[startCoordinateIndex];

        // set some good default
        _currentTurnByTurnWaypoint = _currentHeadingWaypoint;
        _nextTurnByTurnWaypoint = _currentHeadingWaypoint;

        // try to find the current "real" navigation waypoint for turn-by-turn instruction
        //
        startCoordinateIndex++;
        if ((startCoordinateIndex < route.points.length)) {
          _currentTurnByTurnWaypoint = route.points[startCoordinateIndex];
          _nextTurnByTurnWaypoint = _currentTurnByTurnWaypoint;
        }

        startCoordinateIndex++;
        if ((startCoordinateIndex < route.points.length)) {
          _nextTurnByTurnWaypoint = route.points[startCoordinateIndex];
        } else if (_currentHeadingWaypoint == _nextTurnByTurnWaypoint &&
            (calculateDistance(_currentLocation, _currentHeadingWaypoint!.latlng()) <
                (kMinDistanceForNextWaypoint * 2))) {
          // it seems that we have "almost" reached the target because
          // the next target points are pointing to the last rote points.
          targetReached = true;
        }

        // Now we have three wayoints we can calculate the values for the turn-by-turn
        // instruction for the user:
        // - how far the next waypoint is.
        // - what the angle to turn if we reach this waypoint.

        // update the UI
        if (mounted) setState(() {});
      } else {
        targetReached = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    double screenHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    double screenDividerFraction = screenHeight * (6 / 9);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.navigation_poi_dialog),
        talkback: l10n.navigation_poi_dialog_t,
      ),
      body: MergeSemantics(
        child: DividedWidget(
          fraction: screenDividerFraction,
          top: ExcludeSemantics(child: _buildTopPanel()),
          bottom: _buildBottomPanel(),
        ),
      ),
    );
  }

  // Separate method to build the map, isolated from other state changes.
  Widget _buildTopPanel() {
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
            mapRotation: -_currentMapRotation.toDouble(),
            currentLocation: _currentLocation,
            currentWaypoint: _currentHeadingWaypoint?.latlng(),
            marker1: _currentTurnByTurnWaypoint?.latlng(),
            marker2: _nextTurnByTurnWaypoint?.latlng(),
          );
        } else {
          return const Center(child: Text('No route found'));
        }
      },
    );
  }

  Widget _buildBottomPanel() {
    ThemeData theme = Theme.of(context);

    bool isAligned = _isAligned(_currentMapRotation, _currentWaypointHeading);
    Color? backgroundColor = isAligned ? theme.positiveColor : null;

    // The "Background color layer" is required to avoid a complete TalkBack
    // announcement if the background color is changed. IF the user has select
    // one text element, e.g. the direction part, then everytime the color is
    // changing, the Talkback of selected element is activated...anoying.
    //
    return Stack(
      children: [
        // Background color layer
        Container(
          color: backgroundColor,
          height: double.infinity,
          width: double.infinity,
        ),
        // Content layer
        targetReached
            ? const TargetReachedWidget()
            : TurnByTurnInstructionWidget(
                currentCoord: _currentLocation,
                waypoint1: _currentHeadingWaypoint,
                waypoint2: _currentTurnByTurnWaypoint,
                isAligned: isAligned,
                bearing: _needleHeading,
              ),
      ],
    );
  }
}
