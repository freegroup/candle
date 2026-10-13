import 'package:candle/domain/models/latlng_provider.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// What the map shows of a place when the user taps its marker.
class PinInfo {
  const PinInfo({required this.title, required this.subtitle});

  /// The name of the place.
  final String title;

  /// Its address, or empty.
  final String subtitle;
}

abstract class BaseMarkerMapWidget<T extends LatLngProvider> extends StatefulWidget {
  final LatLng currentLocation;
  final List<T> pins;
  final double zoom;
  final bool debug = false;
  final String pinImage;

  /// Name and address of a pin. With it the markers can be tapped and the map
  /// shows the description of the tapped one; without it they are only pictures.
  final PinInfo Function(T pin)? pinInfo;

  /// Called when the user taps the description of a pin: start the navigation to it.
  final void Function(T pin)? onNavigate;

  const BaseMarkerMapWidget(
      {super.key,
      required this.currentLocation,
      this.pins = const [],
      this.zoom = 18,
      required this.pinImage,
      this.pinInfo,
      this.onNavigate});
}
