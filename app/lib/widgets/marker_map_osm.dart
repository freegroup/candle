import 'dart:async';

import 'package:candle/services/compass.dart';
import 'package:candle/widgets/marker_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
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
  StreamSubscription<CompassEvent>? _compassSubscription;
  int _currentMapRotation = 0;

  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    CompassService.instance.initialize().then((_) {
      _compassSubscription = CompassService.instance.updates.handleError((dynamic err) {
        print(err);
      }).listen((compassEvent) async {
        var deviceHeading = (((compassEvent.heading ?? 0) + 360) % 360).toInt();
        if (mounted && (deviceHeading != _currentMapRotation)) {
          setState(() {
            _currentMapRotation = deviceHeading;
            mapController.rotate(
              360 - _currentMapRotation.toDouble(),
            );
          });
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _compassSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    List<Marker> voicePinMarkers = widget.pins.map((pin) {
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
              enableScrollWheel: false,
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
            MarkerLayer(markers: voicePinMarkers),
            //MarkerLayer(markers: [nonRotatingMarker]),
          ],
        ),
      ],
    );
  }
}
