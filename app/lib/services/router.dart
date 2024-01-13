import 'package:candle/models/location_address.dart' as model;
import 'package:candle/services/router_osm.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:candle/models/route.dart' as model;

abstract class RoutingService {
  Future<model.Route?> getPedestrianRoute(LatLng start, LatLng end);
}

class RoutingProvider extends ChangeNotifier {
  RoutingProvider();

  RoutingService _service = OSMRoutingService();

  RoutingService get service => _service;

  void set(RoutingService service) {
    _service = service;
    notifyListeners();
  }
}
