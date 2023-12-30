import 'package:candle/auth/secrets.dart';
import 'package:candle/models/location_address.dart';
import 'package:candle/services/geocoding.dart';

import 'package:flutter_google_maps_webservices/geocoding.dart';
import 'package:google_geocoding_api/google_geocoding_api.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class GoogleMapsGeocodingService implements GeocodingService {
  @override
  Future<LocationAddress?> getGeolocationAddress(LatLng coord) async {
    try {
      final geocoding = GoogleMapsGeocoding(apiKey: GOOGLE_API_KEY);
      final response =
          await geocoding.searchByLocation(Location(lat: coord.latitude, lng: coord.longitude));
      if (response.status == 'OK' && response.results.isNotEmpty) {
        Map<String, String> addressParts = {};
        for (var component in response.results.first.addressComponents) {
          if (component.types.contains('street_number')) {
            addressParts['streetNumber'] = component.longName;
          } else if (component.types.contains('route')) {
            addressParts['street'] = component.longName;
          } else if (component.types.contains('locality')) {
            addressParts['city'] = component.longName;
          } else if (component.types.contains('country')) {
            addressParts['country'] = component.longName;
          } else if (component.types.contains('postal_code')) {
            addressParts['postalCode'] = component.longName;
          } else if (component.types.contains('city_block') &&
              !addressParts.containsKey('street')) {
            // Use 'city_block' if 'street' (route) is not provided
            addressParts['street'] = component.longName;
          } else if (component.types.contains('man_made') && !addressParts.containsKey('street')) {
            // Use 'city_block' if 'street' (route) is not provided
            addressParts['street'] = component.longName;
          }
          // Add more components as needed
        }
        // Extract the refined latitude and longitude from the response
        double refinedLat = response.results.first.geometry.location.lat;
        double refinedLon = response.results.first.geometry.location.lng;

        // Extract formattedAddress from the response
        String? formattedAddress = response.results.first.formattedAddress;

        return LocationAddress(
            name: "",
            formattedAddress: formattedAddress ?? "",
            street: addressParts['street'] ?? "",
            number: addressParts['streetNumber'] ?? "",
            zip: addressParts['postalCode'] ?? "",
            city: addressParts['city'] ?? "",
            country: addressParts['country'] ?? "",
            lat: refinedLat,
            lon: refinedLon);
      } else {
        print('Geocoding failed with status: ${response.status}');
        return _getDefaultLocationAddress();
      }
    } on Exception catch (e) {
      print('Error occurred during geocoding: $e');
      return _getDefaultLocationAddress();
    }
  }

  @override
  Future<List<LocationAddress>> searchNearbyAddress({
    required String addressFragment,
    required Locale locale,
  }) async {
    const bool isDebugMode = true;
    final api = GoogleGeocodingApi(GOOGLE_API_KEY, isLogged: isDebugMode);
    final searchResults = await api.search(
      addressFragment,
      language: locale.countryCode,
    );
    return _parseResults(searchResults);
  }

  List<LocationAddress> _parseResults(GoogleGeocodingResponse results) {
    List<LocationAddress> result = [];
    for (var address in results.results) {
      Map<String, String> addressParts = {};
      for (var component in address.addressComponents) {
        if (component.types.contains('street_number')) {
          addressParts['streetNumber'] = component.longName;
        } else if (component.types.contains('route')) {
          addressParts['street'] = component.longName;
        } else if (component.types.contains('locality')) {
          addressParts['city'] = component.longName;
        } else if (component.types.contains('country')) {
          addressParts['country'] = component.longName;
        } else if (component.types.contains('postal_code')) {
          addressParts['postalCode'] = component.longName;
        } else if (component.types.contains('city_block') && !addressParts.containsKey('street')) {
          // Use 'city_block' if 'street' (route) is not provided
          addressParts['street'] = component.longName;
        } else if (component.types.contains('man_made') && !addressParts.containsKey('street')) {
          // Use 'city_block' if 'street' (route) is not provided
          addressParts['street'] = component.longName;
        }
        // Add more components as needed
      }
      // Extract the refined latitude and longitude from the response
      double refinedLat = address.geometry!.location.lat;
      double refinedLon = address.geometry!.location.lng;

      var loc = LocationAddress(
          name: "",
          formattedAddress: address.formattedAddress ?? "",
          street: addressParts['street'] ?? "",
          number: addressParts['streetNumber'] ?? "",
          zip: addressParts['postalCode'] ?? "",
          city: addressParts['city'] ?? "",
          country: addressParts['country'] ?? "",
          lat: refinedLat,
          lon: refinedLon);

      print("==============================================================");
      result.add(loc);
    }
    return result;
  }

  LocationAddress _getDefaultLocationAddress() {
    return LocationAddress(
      name: "Default Name",
      formattedAddress: "Default Address",
      street: "Default Street",
      number: "Default Number",
      zip: "Default Zip",
      city: "Default City",
      country: "Default Country",
      lat: 0.0,
      lon: 0.0,
    );
  }
}
