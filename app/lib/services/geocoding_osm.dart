import 'package:candle/auth/secrets.dart';
import 'package:candle/models/navigation_point.dart' as model;
import 'package:candle/models/route.dart' as model;
import 'package:candle/models/location_address.dart' as model;

import 'package:candle/services/geocoding.dart';
import 'package:candle/utils/global_logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class OSMGeocodingService implements GeocodingService {
  @override
  Future<model.Route?> getPedestrianRoute(LatLng start, LatLng end) async {
    var client = http.Client();

    try {
      var url = 'https://api.openrouteservice.org/v2/directions/foot-walking/geojson';
      var headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $OPENSTREETMAP_API_KEY'
      };
      var body = json.encode({
        'coordinates': [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude]
        ]
      });

      var response = await client.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var routeLatLng = [
          for (var coord in data['features'][0]['geometry']['coordinates'])
            model.NavigationPoint(coordinate: LatLng(coord[1], coord[0]), annotation: '')
        ];
        routeLatLng.insert(0, model.NavigationPoint(annotation: "", coordinate: start));
        var route = model.Route(name: "current", points: routeLatLng);
        return route.calculateWaypointRoute();
      } else {
        log.e('Failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      log.e('Error occurred during fetching pedestrian route: $e');
    } finally {
      client.close();
    }
    return null;
  }

  @override
  Future<model.LocationAddress?> getGeolocationAddress(LatLng coord) async {
    try {
      String url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${coord.latitude}&lon=${coord.longitude}';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> addressInfo = json.decode(response.body)['address'] ?? {};

        // Use 'road' if available and not empty, otherwise fallback to 'city_block' if available
        String street = addressInfo['road'] ?? '';
        if (street.isEmpty && addressInfo.containsKey('city_block')) {
          street = addressInfo['city_block'];
        }

        return model.LocationAddress(
          lat: coord.latitude,
          lon: coord.longitude,
          name: "",
          formattedAddress: "",
          street: street,
          number: addressInfo['house_number'] ?? '',
          zip: addressInfo['postcode'] ?? '',
          city: addressInfo['city'] ??
              addressInfo['town'] ??
              addressInfo['village'] ??
              addressInfo['municipality'] ??
              addressInfo['suburb'] ??
              '',
          country: addressInfo['country'] ?? '',
        );
      }
    } on Exception catch (error) {
      log.e(error);
    }
    return null;
  }

  @override
  Future<List<model.LocationAddress>> searchNearbyAddress({
    required String addressFragment,
    required Locale locale,
  }) async {
    return [];
  }
}
