import 'package:candle/auth/secrets.dart';
import 'package:candle/models/location_address.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/location.dart';
import 'package:flutter_google_maps_webservices/geocoding.dart';
import 'package:google_geocoding_api/google_geocoding_api.dart';
import 'package:flutter/material.dart';

class GoogleMapsGeocodingService implements GeocodingService {
  @override
  Future<LocationAddress?> getGeolocationAddress({required double lat, required double lon}) async {
    print("$GoogleMapsGeocodingService called.....");
    final geocoding = GoogleMapsGeocoding(apiKey: GOOGLE_API_KEY);

    try {
      final response = await geocoding.searchByLocation(Location(lat: lat, lng: lon));
      if (response.status == 'OK' && response.results.isNotEmpty) {
        Map<String, String> addressParts = {};
        for (var component in response.results.first.addressComponents) {
          if (component.types.contains('street_number')) {
            addressParts['streetNumber'] = component.longName;
          } else if (component.types.contains('route')) {
            addressParts['street'] = component.longName;
            print("SETTING STREET........by street");
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
            print("SETTING STREET........by city_block");
          } else if (component.types.contains('man_made') && !addressParts.containsKey('street')) {
            // Use 'city_block' if 'street' (route) is not provided
            addressParts['street'] = component.longName;
            print("SETTING STREET........by man_made");
          }
          // Add more components as needed
        }

        return LocationAddress(
          street: addressParts['street'] ?? "",
          number: addressParts['streetNumber'] ?? "",
          zip: addressParts['postalCode'] ?? "",
          city: addressParts['city'] ?? "",
          country: addressParts['country'] ?? "",
        );
      } else {
        print('Geocoding failed with status: ${response.status}');
        return null;
      }
    } on Exception catch (e) {
      print('Error occurred during geocoding: $e');
      return null;
    }
  }

  @override
  Future<List<AddressSearchResult>> searchNearbyAddress({
    required String addressFragment,
    required Locale locale,
  }) async {
    const bool isDebugMode = true;
    final api = GoogleGeocodingApi(GOOGLE_API_KEY, isLogged: isDebugMode);
    final searchResults = await api.search(
      addressFragment,
      language: locale.countryCode,
    );
    print(searchResults);
    return _parseResults(searchResults);
  }

  List<AddressSearchResult> _parseResults(GoogleGeocodingResponse results) {
    List<AddressSearchResult> result = [];
    for (var address in results.results) {
      print(address);
      result.add(AddressSearchResult(
        formattedAddress: address.formattedAddress,
        lat: 0,
        lng: 0,
      ));
    }
    return result;
  }
}
