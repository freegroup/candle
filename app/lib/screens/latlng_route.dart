import 'dart:async';

import 'package:candle/guidance/guidance.dart';
import 'package:candle/guidance/simple.dart';
import 'package:candle/models/latlng_provider.dart';
import 'package:candle/models/navigation_point.dart' as model;
import 'package:candle/models/route.dart' as model;
import 'package:candle/services/compass.dart';
import 'package:candle/services/location.dart';
import 'package:candle/services/router.dart';
import 'package:candle/theme_data.dart';
import 'package:candle/utils/configuration.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/utils/semantic.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:candle/widgets/divided_widget.dart';
import 'package:candle/widgets/route_map_osm.dart';
import 'package:candle/widgets/target_reached.dart';
import 'package:candle/widgets/turn_by_turn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class LatLngRouteScreen extends StatefulWidget {
  final LatLng source;
  final LatLng target;
  final model.Route? route;

  const LatLngRouteScreen({super.key, required this.source, required this.target, this.route});

  @override
  State<LatLngRouteScreen> createState() => _ScreenState();
}

class _ScreenState extends State<LatLngRouteScreen> with SemanticAnnouncer {
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<Position>? _locationSubscription;

  late BaseGuidance _guidance;
  late Future<model.Route?> _stateRoute;

  int _currentMapRotation = 0;
  int _currentWaypointHeading = 0;
  int _distanceToTurnByTurnWaypoint = 0;

  int _distanceToTarget = 0;

  // the current location of the user given by the GPS signal
  late LatLng _currentLocation;
  // this is the waypoint where the compas is pointing
  model.NavigationPoint? _currentHeadingWaypoint;
  // this is the next routing waypoint for the turn-by-turn instruction
  model.NavigationPoint? _currentTurnByTurnWaypoint;
  // this is the successor routing waypoint for the turn-by-turn instruction
  model.NavigationPoint? _nextTurnByTurnWaypoint;

  int _currentWaypointSegmentIndex = -1;
  int _needleHeading = 0;

  _ScreenState() {
    _guidance = SimpleGuidance();
  }

  @override
  void initState() {
    super.initState();

    _guidance.initialize(context);

    _stateRoute = widget.route != null
        ? Future(() => widget.route)
        : _calculateRoute(widget.source, widget.target);
    _currentLocation = widget.source;
    _updateWaypoints(_currentLocation);
    _guidance.onRouteChange(context, _stateRoute);

    _locationSubscription = LocationService.instance.listen.handleError((dynamic err) {
      log.e(err);
    }).listen((newLocation) async {
      _currentLocation = LatLng(newLocation.latitude, newLocation.longitude);
      _updateWaypoints(_currentLocation);
      _guidance.onLocationChange(context, _currentLocation);
      if (context.mounted && _currentHeadingWaypoint != null) {
        var route = await _stateRoute;
        if (route == null) return;

        var newWaypointDistance =
            calculateDistance(_currentLocation, _currentTurnByTurnWaypoint!.latlng()).toInt();
        var resumingOverallDistance =
            route.calculateResumingLengthFromWaypoint(_currentHeadingWaypoint!).toInt() +
                newWaypointDistance;
        if (mounted &&
            (newWaypointDistance != _distanceToTurnByTurnWaypoint ||
                resumingOverallDistance != _distanceToTarget)) {
          setState(() {
            _distanceToTurnByTurnWaypoint = newWaypointDistance;
            _distanceToTarget = resumingOverallDistance;
          });
        }
      }
    });

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        log.e(err);
      }).listen((compassEvent) async {
        if (context.mounted && _currentHeadingWaypoint != null) {
          var waypointHeading =
              calculateNorthBearing(_currentLocation, _currentHeadingWaypoint!.latlng());
          var deviceHeading = (((compassEvent.heading ?? 0) + 360) % 360).toInt();
          var needleHeading = -(deviceHeading - waypointHeading);
          // ignore: use_build_context_synchronously
          _guidance.onCompassChange(context, deviceHeading, waypointHeading);

          if (mounted && (deviceHeading != _currentMapRotation)) {
            setState(() {
              _currentMapRotation = deviceHeading;
              _currentWaypointHeading = waypointHeading;
              _needleHeading = needleHeading;
            });
          }
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizations l10n = AppLocalizations.of(context)!;
      announceOnShow(l10n.navigation_announcement_hint);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _compassSubscription?.cancel();
    _locationSubscription?.cancel();
    _guidance.cancel();
  }

  Future<model.Route?> _calculateRoute(LatLng start, LatLng target) async {
    try {
      var geo = Provider.of<RoutingProvider>(context, listen: false).service;
      // do not remove the "await"...the catch block isn't working if we do not
      // await the result ...
      return await geo.getPedestrianRoute(start, target);
    } catch (e) {
      log.e("Error fetching route: $e");
      return null;
    }
  }

  void _updateWaypoints(LatLng location) async {
    if (_guidance.targetReached == true) {
      return;
    }

    final route = await _stateRoute;
    if (route == null) {
      _stateRoute = _calculateRoute(location, widget.target);
      // ignore: use_build_context_synchronously
      _guidance.onRouteChange(context, _stateRoute);
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
      _stateRoute = _calculateRoute(location, widget.target);
      // ignore: use_build_context_synchronously
      _guidance.onRouteChange(context, _stateRoute);
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
      log.d("index changed because of closer segment startCoordinateIndex:$startCoordinateIndex");
    }

    if (startCoordinateIndex > _currentWaypointSegmentIndex) {
      _currentWaypointSegmentIndex = startCoordinateIndex;

      if (startCoordinateIndex < route.points.length - 1) {
        // index the next point of the first segment
        startCoordinateIndex++;
        _currentHeadingWaypoint = route.points[startCoordinateIndex];
        // ignore: use_build_context_synchronously
        _guidance.onWaypointChange(context, _currentHeadingWaypoint);

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
          // ignore: use_build_context_synchronously
          _guidance.setTargetReached(context);
        }

        // Now we have three wayoints we can calculate the values for the turn-by-turn
        // instruction for the user:
        // - how far the next waypoint is.
        // - what the angle to turn if we reach this waypoint.

        if (context.mounted) setState(() {});
      } else {
        // ignore: use_build_context_synchronously
        _guidance.setTargetReached(context);
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
        title: Text(l10n.screen_header_navigation_poi),
        talkback: l10n.screen_header_navigation_poi_t,
      ),
      body: MergeSemantics(
        child: DividedWidget(
          fraction: screenDividerFraction,
          top: _buildTopPane(context),
          bottom: _buildBottomPane(context),
        ),
      ),
    );
  }

  // Separate method to build the map, isolated from other state changes.
  Widget _buildTopPane(BuildContext context) {
    return ExcludeSemantics(
      child: FutureBuilder<model.Route?>(
        future: _stateRoute,
        builder: (context, routeSnapshot) {
          if (routeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (routeSnapshot.hasError) {
            return Center(child: Text('Error fetching route: ${routeSnapshot.error}'));
          } else if (routeSnapshot.hasData) {
            return FutureBuilder<List<LatLngProvider>>(
              future: _guidance.getMarker(),
              builder: (context, pinsSnapshot) {
                if (pinsSnapshot.connectionState == ConnectionState.waiting) {
                  // Optionally, return an empty container or a loading spinner
                  return const Center(child: CircularProgressIndicator());
                } else if (pinsSnapshot.hasError) {
                  // Handle the error state
                  return Center(child: Text('Error fetching voice pins: ${pinsSnapshot.error}'));
                } else {
                  // Both futures are resolved, return your widget
                  return RouteMapWidget(
                    route: routeSnapshot.data!,
                    mapRotation: -_currentMapRotation.toDouble(),
                    currentLocation: _currentLocation,
                    currentWaypoint: _currentHeadingWaypoint?.latlng(),
                    marker1: _currentTurnByTurnWaypoint?.latlng(),
                    marker2: _nextTurnByTurnWaypoint?.latlng(),
                    marker: pinsSnapshot.data!,
                  );
                }
              },
            );
          } else {
            return const Center(child: Text('No route found'));
          }
        },
      ),
    );
  }

  // Separate method to build the info pane, isolated from other state changes.
  Widget _buildBottomPane(BuildContext context) {
    ThemeData theme = Theme.of(context);

    bool isAligned = _guidance.isAligned(_currentMapRotation, _currentWaypointHeading);
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
        _guidance.targetReached
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
