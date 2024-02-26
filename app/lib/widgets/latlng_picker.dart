import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LatLngPickerWidget extends StatefulWidget {
  static void _defaultVoidCallback() {}

  final LatLng latlng;
  final Function(LatLng) onLatLngChanged;
  final VoidCallback onLock;
  final VoidCallback onUnlock;

  const LatLngPickerWidget({
    required this.latlng,
    required this.onLatLngChanged,
    this.onLock = _defaultVoidCallback,
    this.onUnlock = _defaultVoidCallback,
    super.key,
  });

  @override
  State<LatLngPickerWidget> createState() => _WidgetState();
}

class _WidgetState extends State<LatLngPickerWidget> {
  static const double pointSize = 65;
  static double pointY = 150;
  static const double zoom = 18;
  late LatLng _latlng;
  // Variables to track scale gesture
  bool _isLongPressActive = false;

  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    _latlng = widget.latlng;
    WidgetsBinding.instance.addPostFrameCallback((_) => initPoint(context));
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    debugPrintGestureArenaDiagnostics = true;
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
              onLongPress: (tapPosition, point) {
                setState(() {
                  _isLongPressActive = !_isLongPressActive;
                  _isLongPressActive ? widget.onUnlock() : widget.onLock();
                });
              },
              onPositionChanged: (_, __) => updatePoint(context),
              initialCenter: widget.latlng,
              initialZoom: zoom,
              minZoom: 3,
              interactionOptions: InteractionOptions(
                flags: _isLongPressActive ? InteractiveFlag.drag : InteractiveFlag.none,
              )),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'de.freegroup.candle',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: pointSize,
                  height: pointSize,
                  point: _latlng,
                  child: const Icon(Icons.circle, size: 10, color: Colors.black),
                )
              ],
            )
          ],
        ),
        Visibility(
          visible: !_isLongPressActive,
          child: Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                color: Colors.amber.withOpacity(0.6),
              ),
            ),
          ),
        ),
        Positioned(
          top: pointY - pointSize / 2,
          left: _getPointX(context) - pointSize / 2,
          child: const IgnorePointer(
            child: Icon(
              Icons.center_focus_strong_outlined,
              size: pointSize,
              color: Colors.black,
            ),
          ),
        ),
        Positioned(
          top: pointY + pointSize / 2 + 6,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Text(
              _isLongPressActive ? '(Drag to Move)' : '(Long Press to Change)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        )
      ],
    );
  }

  void updatePoint(BuildContext context) {
    setState(() {
      _latlng = mapController.camera.pointToLatLng(Point(_getPointX(context), pointY));
    });
    widget.onLatLngChanged(_latlng);
  }

  void initPoint(BuildContext context) {
    setState(() {
      pointY = mapController.camera.latLngToScreenPoint(_latlng).y;
    });
  }

  double _getPointX(BuildContext context) => MediaQuery.sizeOf(context).width / 2;
}
