import 'dart:async';

import 'package:candle/services/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:candle/models/location.dart' as model;

class LocationMapScreen extends StatefulWidget {
  final model.Location location;

  const LocationMapScreen({super.key, required this.location});

  @override
  State<LocationMapScreen> createState() => _ScreenState();
}

class _ScreenState extends State<LocationMapScreen> {
  late model.Location stateLocation;
  model.Location currentLocation = model.Location(lat: 40.0, lon: 8.0, name: "");

  void updateGpsLocation() async {
    var gps = await LocationService.instance.location;
    if (gps != null && mounted) {
      setState(() {
        currentLocation = model.Location(lat: gps.latitude!, lon: gps.longitude!, name: "");
      });
    }
    // Sie können hier auch einen Debouncer hinzufügen, um die Aktualisierungsrate zu begrenzen
  }

  @override
  void initState() {
    super.initState();
    updateGpsLocation();
    Timer.periodic(const Duration(seconds: 10), (Timer t) => updateGpsLocation());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location.name),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(widget.location.lat, widget.location.lon),
          initialZoom: 18,
          initialRotation: 0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(widget.location.lat, widget.location.lon), // center of 't Gooi
                radius: 5,
                useRadiusInMeter: true,
                color: Colors.red.withOpacity(0.3),
                borderColor: Colors.red.withOpacity(0.7),
                borderStrokeWidth: 3,
              )
            ],
          ),
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(currentLocation.lat, currentLocation.lon), // center of 't Gooi
                radius: 5,
                useRadiusInMeter: true,
                color: Colors.green.withOpacity(0.5),
                borderColor: Colors.green.withOpacity(0.9),
                borderStrokeWidth: 3,
              )
            ],
          ),
        ],
      ),
    );
  }
}
