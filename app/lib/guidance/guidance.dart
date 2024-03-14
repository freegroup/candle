import 'package:candle/models/latlng_provider.dart';
import 'package:candle/models/navigation_point.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:candle/models/route.dart' as model;

abstract class BaseGuidance {
  // it is a oneTime toggle. Once the target is reached, it never gets back to "false"
  bool _targetReached = false;
  bool get targetReached => _targetReached;

  @mustCallSuper
  void initialize(BuildContext context) {
    _targetReached = false;
  }

  @mustCallSuper
  void cancel() {
    //
  }

  void onLocationChange(BuildContext context, LatLng location);
  void onCompassChange(BuildContext context, int deviceHeading, int waypointHeading);
  void onWaypointChange(BuildContext context, NavigationPoint? waypoint);
  void onRouteChange(BuildContext context, Future<model.Route?> route);

  void setTargetReached(BuildContext context) {
    // it is a oneTime toggle. Once the target is reached, it never gets back to "false"
    _targetReached = true;
  }

  Future<List<LatLngProvider>> getMarker();

  bool isAligned(int mapRotation, int waypointHeading) {
    var diff = mapRotation - waypointHeading;
    return (diff.abs() <= 8) || (diff.abs() >= 352);
  }
}
