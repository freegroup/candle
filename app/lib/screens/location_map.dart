import 'dart:async';

import 'package:candle/services/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationMapScreen extends StatefulWidget {
  final LatLng location;

  const LocationMapScreen({super.key, required this.location});

  @override
  State<LocationMapScreen> createState() => _ScreenState();
}

class _ScreenState extends State<LocationMapScreen> {
  late LatLng stateLocation;
  LatLng currentLocation = const LatLng(40.0, 8.0);

  void updateGpsLocation() async {
    var gps = await LocationService.instance.location;
    if (gps != null && mounted) {
      setState(() {
        currentLocation = gps;
      });
    }
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
        title: Text("Map"),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: widget.location,
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
                point: widget.location, // center of 't Gooi
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
                point: currentLocation, // center of 't Gooi
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
