import 'dart:async';

import 'package:candle/data/services/compass/compass_service.dart';
import 'package:provider/provider.dart';
import 'package:candle/ui/core/widgets/marker_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MarkerMapWidget extends BaseMarkerMapWidget {
  final double mapRotation = 0;

  const MarkerMapWidget({
    super.key,
    required super.currentLocation,
    super.zoom,
    super.pins,
    required super.pinImage,
  });

  @override
  State<MarkerMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<MarkerMapWidget> {
  StreamSubscription<double>? _compassSubscription;
  int _currentMapRotation = 0;

  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    _compassSubscription = context.read<CompassService>().headings().listen((heading) {
      final deviceHeading = heading.round() % 360;
      if (mounted && deviceHeading != _currentMapRotation) {
        setState(() {
          _currentMapRotation = deviceHeading;
          mapController.rotate(360 - _currentMapRotation.toDouble());
        });
      }
    }, onError: (Object e) => debugPrint('$e'));
  }

  @override
  void dispose() {
    super.dispose();
    _compassSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {

    List<Marker> locationNoteMarkers = widget.pins.map((pin) {
      return Marker(
        width: 35.0,
        height: 35.0,
        point: pin.latlng(),
        rotate: true,
        child: Image.asset(widget.pinImage),
      );
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: widget.currentLocation,
            initialZoom: widget.zoom,
            initialRotation: _currentMapRotation.toDouble(),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
            ),
            maxZoom: widget.zoom,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              //urlTemplate: 'https://tiles.stadiamaps.com/tiles/stamen_toner/{z}/{x}/{y}.png',
              userAgentPackageName: 'de.freegroup.candle',
            ),
            MarkerLayer(markers: locationNoteMarkers),
            //MarkerLayer(markers: [nonRotatingMarker]),
          ],
        ),
      ],
    );
  }
}
