import 'package:candle/models/latlng_provider.dart';
import 'package:candle/models/route.dart' as model;
import 'package:candle/models/voicepin.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

abstract class BaseRouteMapWidget extends StatefulWidget {
  final model.Route? route;
  final double mapRotation;
  final LatLng currentLocation;
  final LatLng? currentWaypoint;
  final LatLng? marker1;
  final LatLng? marker2;
  final List<LatLngProvider> marker;
  final double zoom;
  final double stroke;
  final bool debug = false;

  const BaseRouteMapWidget({
    super.key,
    this.route,
    required this.mapRotation,
    required this.currentLocation,
    this.currentWaypoint,
    this.marker1,
    this.marker2,
    this.marker = const [],
    this.zoom = 18,
    this.stroke = 15,
  });
}
