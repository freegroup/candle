import 'dart:async';

import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/domain/models/latlng_provider.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:candle/ui/core/widgets/marker_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MarkerMapWidget<T extends LatLngProvider> extends BaseMarkerMapWidget<T> {
  final double mapRotation = 0;

  const MarkerMapWidget({
    super.key,
    required super.currentLocation,
    super.zoom,
    super.pins,
    required super.pinImage,
    super.pinInfo,
    super.onNavigate,
  });

  @override
  State<MarkerMapWidget<T>> createState() => _RouteMapWidgetState<T>();
}

class _RouteMapWidgetState<T extends LatLngProvider> extends State<MarkerMapWidget<T>> {
  StreamSubscription<double>? _compassSubscription;
  int _currentMapRotation = 0;

  late MapController mapController;

  // The map keeps the user's position in the middle until the user moves the map.
  bool _following = true;

  // The pin the user tapped; its description is shown at the top of the map.
  T? _selected;

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
  void didUpdateWidget(MarkerMapWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_following && widget.currentLocation != oldWidget.currentLocation) {
      mapController.move(widget.currentLocation, mapController.camera.zoom);
    }
    // The list of pins can come anew with other objects: the tapped pin is found
    // again by its position, and it is no longer selected when it is gone.
    final selected = _selected;
    if (selected != null) _selected = _pinAt(selected.latlng());
  }

  T? _pinAt(LatLng position) {
    for (final pin in widget.pins) {
      if (pin.latlng() == position) return pin;
    }
    return null;
  }

  bool _isSelected(T pin) {
    final selected = _selected;
    return selected != null && selected.latlng() == pin.latlng();
  }

  @override
  void dispose() {
    super.dispose();
    _compassSubscription?.cancel();
  }

  // Only the user's finger ends the following, not the compass or a new position.
  void _onMapMoved(MapCamera camera, bool hasGesture) {
    if (hasGesture && _following) setState(() => _following = false);
  }

  // Brings the user's position back to the middle; the zoom stays as the user set it.
  void _center() {
    mapController.move(widget.currentLocation, mapController.camera.zoom);
    setState(() => _following = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final myPosition = Marker(
      width: _MyPositionMarker.haloSize,
      height: _MyPositionMarker.haloSize,
      point: widget.currentLocation,
      child: const _MyPositionMarker(),
    );

    // Pins that can be tapped get a larger area than their picture, so they are easy to hit.
    final canSelect = widget.pinInfo != null;
    List<Marker> locationNoteMarkers = widget.pins.map((pin) {
      final imageSize = _isSelected(pin) ? 50.0 : 35.0;
      final image = Image.asset(widget.pinImage, width: imageSize, height: imageSize);
      return Marker(
        width: canSelect ? 56.0 : 35.0,
        height: canSelect ? 56.0 : 35.0,
        point: pin.latlng(),
        rotate: true,
        child: canSelect
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selected = pin),
                child: Center(child: image),
              )
            : image,
      );
    }).toList();

    final selected = _selected;
    final pinInfo = widget.pinInfo;

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
            onPositionChanged: _onMapMoved,
            // a tap beside the pins closes the description of the tapped pin
            onTap: (tapPosition, point) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              //urlTemplate: 'https://tiles.stadiamaps.com/tiles/stamen_toner/{z}/{x}/{y}.png',
              userAgentPackageName: 'de.freegroup.candle',
            ),
            // the own position last, so it lies on top of the places
            MarkerLayer(markers: [...locationNoteMarkers, myPosition]),
            //MarkerLayer(markers: [nonRotatingMarker]),
          ],
        ),
        // the description of the tapped pin at the top, so it does not get in the
        // way of the button at the bottom
        if (selected != null && pinInfo != null)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _PinCard(
                info: pinInfo(selected),
                action: l10n.button_navigate_poi,
                onTap: () => widget.onNavigate?.call(selected),
              ),
            ),
          ),
        if (!_following)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                button: true,
                label: l10n.button_map_center_t,
                excludeSemantics: true,
                onTap: _center,
                child: ElevatedButton.icon(
                  onPressed: _center,
                  icon: const Icon(Icons.my_location, size: 28),
                  label: Text(l10n.button_map_center),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.cardColor,
                    textStyle: theme.textTheme.titleLarge,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The description of the tapped pin at the top of the map: its name, its
/// address and what a tap on it does. Large and fixed, because the map itself
/// turns with the compass.
class _PinCard extends StatelessWidget {
  const _PinCard({required this.info, required this.action, required this.onTap});

  final PinInfo info;

  /// What a tap does, e.g. "Start navigation".
  final String action;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.cardColor;
    const shape = BorderRadius.all(Radius.circular(20));
    return Semantics(
      button: true,
      label: '${info.title}, ${info.subtitle}. $action',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: theme.primaryColor,
        borderRadius: shape,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        info.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: color, fontWeight: FontWeight.bold),
                      ),
                      if (info.subtitle.isNotEmpty)
                        Text(
                          info.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(color: color),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        action,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.navigation, size: 40, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The user's own position on the map: a blue dot, so it stands out from the
/// yellow markers of the places, with a halo that pulses. With animations turned
/// off in the system settings only the dot is shown.
class _MyPositionMarker extends StatefulWidget {
  const _MyPositionMarker();

  static const dotSize = 40.0;

  /// How far the halo grows; the marker on the map needs this much room.
  static const haloSize = 96.0;

  // the blue of assets/images/my_location_marker.png
  static const _blue = Color(0xFF1A73E8);

  @override
  State<_MyPositionMarker> createState() => _MyPositionMarkerState();
}

class _MyPositionMarkerState extends State<_MyPositionMarker> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // the halo grows from the dot outwards and fades while it grows
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final progress = _pulse.value;
            final size = _MyPositionMarker.dotSize +
                (_MyPositionMarker.haloSize - _MyPositionMarker.dotSize) * progress;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _MyPositionMarker._blue.withValues(alpha: 0.4 * (1 - progress)),
              ),
            );
          },
        ),
        Image.asset(
          'assets/images/my_location_marker.png',
          width: _MyPositionMarker.dotSize,
          height: _MyPositionMarker.dotSize,
        ),
      ],
    );
  }
}
