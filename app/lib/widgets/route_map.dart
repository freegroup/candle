import 'package:candle/models/route.dart' as model;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

abstract class BaseRouteMapWidget extends StatefulWidget {
  final model.Route route;
  final double mapRotation;
  final LatLng currentLocation;
  final LatLng? currentWaypoint;
  final LatLng? marker1;
  final LatLng? marker2;
  final double zoom;
  final double stroke;
  final bool debug = false;

  const BaseRouteMapWidget({
    super.key,
    required this.route,
    required this.mapRotation,
    required this.currentLocation,
    this.currentWaypoint,
    this.marker1,
    this.marker2,
    this.zoom = 18,
    this.stroke = 15,
  });
}
