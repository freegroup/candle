import 'dart:convert';

import 'package:candle/models/location_address.dart' as model;
import 'package:candle/models/location_address.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OSMGeocodingService implements GeocodingService {
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
          formattedAddress: formattedAddress(addressInfo),
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
  Future<List<LocationAddress>> searchNearbyAddress({
    required String addressFragment,
    required Locale locale,
  }) async {
    try {
      String url =
          'https://nominatim.openstreetmap.org/search?format=json&q=$addressFragment&addressdetails=1&accept-language=${locale.languageCode}&limit=5';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> results = json.decode(response.body);
        return results.map((result) {
          Map<String, dynamic> addressInfo = result['address'] ?? {};
          return LocationAddress(
            lat: double.tryParse(result['lat']) ?? 0.0,
            lon: double.tryParse(result['lon']) ?? 0.0,
            name: result['display_name'] ?? '',
            formattedAddress: result['display_name'] ?? '',
            street: addressInfo['road'] ?? addressInfo['pedestrian'] ?? '',
            number: addressInfo['house_number'] ?? '',
            zip: addressInfo['postcode'] ?? '',
            city: addressInfo['city'] ?? addressInfo['town'] ?? addressInfo['village'] ?? '',
            country: addressInfo['country'] ?? '',
          );
        }).toList();
      }
    } catch (e) {
      // Handle the exception
    }
    return [];
  }

  String formattedAddress(Map<String, dynamic> addressInfo) {
    String street = addressInfo['road'] ?? '';
    if (street.isEmpty && addressInfo.containsKey('city_block')) {
      street = addressInfo['city_block'];
    }

    String number = addressInfo['house_number'] ?? "";
    String zip = addressInfo['postcode'] ?? '';
    String city = addressInfo['city'] ??
        addressInfo['town'] ??
        addressInfo['village'] ??
        addressInfo['municipality'] ??
        addressInfo['suburb'] ??
        '';

    return "$street $number, $zip $city";
  }
}
