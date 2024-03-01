import 'package:candle/models/navigation_point.dart' as model;
import 'package:candle/utils/colors.dart';
import 'package:candle/utils/configuration.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/widgets/route_map.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;

class RouteMapWidget extends BaseRouteMapWidget {
  static google.BitmapDescriptor? customCircleIcon;

  const RouteMapWidget({
    super.key,
    super.route,
    required super.mapRotation,
    required super.currentLocation,
    super.currentWaypoint,
    super.marker1,
    super.marker2,
    super.zoom,
  });

  @override
  State<RouteMapWidget> createState() => _WidgetState();
}

class _WidgetState extends State<RouteMapWidget> {
  google.GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    if (RouteMapWidget.customCircleIcon == null) {
      _loadCustomIcon(); // Load the icon only if it's null
    }
  }

  void _loadCustomIcon() async {
    RouteMapWidget.customCircleIcon = await google.BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 1),
      'assets/images/compass_marker.png', // Path to your circle icon
    );
  }

  @override
  void didUpdateWidget(RouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mapRotation != oldWidget.mapRotation ||
        widget.currentLocation != oldWidget.currentLocation) {
      centerMapOnCurrentLocation();
    }
  }

  void centerMapOnCurrentLocation() {
    _mapController?.moveCamera(
      google.CameraUpdate.newCameraPosition(
        google.CameraPosition(
          target: google.LatLng(
            widget.currentLocation.latitude,
            widget.currentLocation.longitude,
          ),
          bearing: (360) - widget.mapRotation.toDouble(),
          zoom: widget.zoom,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    log.d("Building map...");

    ThemeData theme = Theme.of(context);
    final google.Marker currentLocationMarker = google.Marker(
      markerId: const google.MarkerId('current_location'),
      position: google.LatLng(widget.currentLocation.latitude, widget.currentLocation.longitude),
      icon: RouteMapWidget.customCircleIcon ?? google.BitmapDescriptor.defaultMarker,
      anchor: const Offset(0.5, 0), // Set anchor to top center
    );

    Set<google.Circle> circles = {};
    google.Polyline? routePolyline;
    // Create a circle for the waypoint
    if (widget.currentWaypoint != null) {
      circles.add(google.Circle(
        circleId: const google.CircleId('waypoint'),
        center: google.LatLng(widget.currentWaypoint!.latitude, widget.currentWaypoint!.longitude),
        radius: widget.debug ? 30 : 10, // Adjust the size as needed
        fillColor: Colors.red.withOpacity(0.8),
        strokeColor: Colors.red,
        strokeWidth: 2,
      ));
    }
    if (widget.debug) {
      if (widget.marker1 != null) {
        circles.add(google.Circle(
          circleId: const google.CircleId('marker1'),
          center: google.LatLng(widget.marker1!.latitude, widget.marker1!.longitude),
          radius: 20,
          fillColor: const Color.fromARGB(255, 57, 54, 244).withOpacity(0.8),
          strokeWidth: 2,
        ));
      }
      if (widget.marker2 != null) {
        circles.add(google.Circle(
          circleId: const google.CircleId('marker2'),
          center: google.LatLng(widget.marker2!.latitude, widget.marker2!.longitude),
          radius: 12,
          fillColor: const Color.fromARGB(255, 44, 215, 113).withOpacity(0.8),
          strokeWidth: 2,
        ));
      }
    }

    if (widget.route != null) {
      circles.addAll(widget.route!.points.map((point) {
        return google.Circle(
          circleId: google.CircleId(point.toString()),
          center: google.LatLng(point.coordinate.latitude, point.coordinate.longitude),
          radius: 4,
          fillColor: point.type == model.NavigationPointType.syntetic
              ? theme.primaryColor.withOpacity(0.5)
              : darken(theme.primaryColor, 0.15),
          strokeWidth: 1,
          strokeColor: darken(theme.primaryColor, 0.15),
        );
      }).toSet());
      // Create a polyline for the route
      routePolyline = google.Polyline(
        polylineId: const google.PolylineId('route'),
        points: widget.route!.points
            .map((point) => google.LatLng(
                  point.coordinate.latitude,
                  point.coordinate.longitude,
                ))
            .toList(),
        color: theme.primaryColor,
        width: 10,
      );
    }

    return google.GoogleMap(
      onMapCreated: (google.GoogleMapController controller) {
        _mapController = controller;
        centerMapOnCurrentLocation(); // Ensure map is centered on current location with correct heading
        controller.setMapStyle(kMapStyle);
      },
      initialCameraPosition: google.CameraPosition(
        target: google.LatLng(
          widget.currentLocation.latitude,
          widget.currentLocation.longitude,
        ),
        zoom: widget.zoom,
        bearing: widget.mapRotation,
      ),
      markers: {currentLocationMarker},
      polylines: routePolyline != null ? {routePolyline} : {},
      circles: circles,
      scrollGesturesEnabled: false, // Disable scroll gestures
      zoomGesturesEnabled: false, // Disable zoom gestures
      tiltGesturesEnabled: false, // Disable tilt gestures
      rotateGesturesEnabled: false, // Disable rotate gestures
      zoomControlsEnabled: false,
      compassEnabled: false,
    );
  }
}
