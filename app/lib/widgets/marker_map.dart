import 'package:candle/models/latlng_provider.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

abstract class BaseMarkerMapWidget extends StatefulWidget {
  final LatLng currentLocation;
  final List<LatLngProvider> pins;
  final double zoom;
  final bool debug = false;
  final String pinImage;

  const BaseMarkerMapWidget(
      {super.key,
      required this.currentLocation,
      this.pins = const [],
      this.zoom = 18,
      required this.pinImage});
}
