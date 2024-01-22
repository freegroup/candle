import 'package:candle/widgets/route_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteMapWidget extends BaseRouteMapWidget {
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
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  @override
  void didUpdateWidget(RouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    mapController.moveAndRotate(
      widget.currentLocation,
      widget.zoom,
      widget.mapRotation,
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    List<LatLng> routePoints = widget.route == null
        ? []
        : widget.route!.points
            .map((navPoint) =>
                navPoint.latlng()) // Konvertieren Sie jeden NavigationPoint in ein LatLng-Objekt
            .toList();

    var polylines = <Polyline>[
      Polyline(
        points: routePoints,
        strokeWidth: widget.stroke,
        color: theme.primaryColor, // Verwenden Sie Ihre primaryColor für die Route
      ),
      // Sie können hier weitere Polylinien hinzufügen, falls erforderlich
    ];

    var markers = <CircleMarker>[
      if (widget.currentWaypoint != null)
        CircleMarker(
          radius: widget.debug ? 30 : 10,
          color: Colors.red.withOpacity(0.8),
          point: widget.currentWaypoint!,
        ),
      if (widget.debug)
        if (widget.marker1 != null)
          CircleMarker(
            color: const Color.fromARGB(255, 57, 54, 244).withOpacity(0.8),
            radius: 15.0,
            point: widget.marker1!,
          ),
      if (widget.debug)
        if (widget.marker2 != null)
          CircleMarker(
            color: const Color.fromARGB(255, 44, 215, 113).withOpacity(0.8),
            radius: 10,
            point: widget.marker2!,
          ),
    ];

    /** is working as well. Do not remove code!!
    var nonRotatingMarker = Marker(
      width: 30.0,
      height: 30.0,
      point: widget.currentLocation, // Der Punkt auf der Karte, an dem das Widget platziert wird
      child: Transform.rotate(
        angle: -widget.mapRotation * (pi / 180), // Gegenrotation
        child: Icon(
          Icons.pin_drop, // Das gewählte Icon
          color: Colors.blue,
        ),
      ),
    );
    */

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: widget.currentLocation,
            initialZoom: widget.zoom,
            initialRotation: widget.mapRotation,
            interactionOptions: const InteractionOptions(
              enableScrollWheel: false,
              flags: InteractiveFlag.none,
            ),
            maxZoom: widget.zoom,
            minZoom: 3,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              //urlTemplate: 'https://tiles.stadiamaps.com/tiles/stamen_toner/{z}/{x}/{y}.png',
              userAgentPackageName: 'de.freegroup.candle',
            ),
            PolylineLayer(polylines: polylines),
            CircleLayer(circles: markers),
            //MarkerLayer(markers: [nonRotatingMarker]),
          ],
        ),
        Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: const Offset(0, 150 / 2),
            child: Image.asset(
              'assets/images/location_marker.png', // Pfad zu Ihrem Bild
              width: 150.0, // Breite des Bildes
              height: 150.0, // Höhe des Bildes
            ),
          ),
        ),
      ],
    );
  }
}
