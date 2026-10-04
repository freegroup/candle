import 'dart:convert';

import 'package:candle/domain/models/location_address.dart';
import 'package:candle/config/app_config.dart';
import 'package:candle/utils/result.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Address lookup with the OpenStreetMap Nominatim service.
class NominatimClient {
  NominatimClient({required this._client});

  final http.Client _client;

  /// The address at [position]; its name is empty.
  Future<Result<LocationAddress>> reverse(LatLng position) async {
    final json = await _get('/reverse', {
      'format': 'json',
      'lat': '${position.latitude}',
      'lon': '${position.longitude}',
    });
    if (json case Ok(:final value)) {
      final address = (value as Map<String, dynamic>)['address'] as Map<String, dynamic>? ?? {};
      final street = _street(address);
      final number = address['house_number'] as String? ?? '';
      final zip = address['postcode'] as String? ?? '';
      final city = _city(address);
      return Result.ok(LocationAddress(
        name: '',
        formattedAddress: '$street $number, $zip $city',
        street: street,
        number: number,
        zip: zip,
        city: city,
        country: address['country'] as String? ?? '',
        lat: position.latitude,
        lon: position.longitude,
      ));
    }
    return Result.error((json as Error).error);
  }

  /// Up to five addresses matching [query], named in [languageCode].
  Future<Result<List<LocationAddress>>> search(String query, String languageCode) async {
    final json = await _get('/search', {
      'format': 'json',
      'q': query,
      'addressdetails': '1',
      'accept-language': languageCode,
      'limit': '5',
    });
    if (json case Ok(:final value)) {
      return Result.ok([
        for (final result in (value as List).cast<Map<String, dynamic>>())
          _searchResult(result),
      ]);
    }
    return Result.error((json as Error).error);
  }

  LocationAddress _searchResult(Map<String, dynamic> result) {
    final address = result['address'] as Map<String, dynamic>? ?? {};
    final displayName = result['display_name'] as String? ?? '';
    return LocationAddress(
      name: displayName,
      formattedAddress: displayName,
      street: address['road'] as String? ?? address['pedestrian'] as String? ?? '',
      number: address['house_number'] as String? ?? '',
      zip: address['postcode'] as String? ?? '',
      city: address['city'] as String? ?? address['town'] as String? ?? address['village'] as String? ?? '',
      country: address['country'] as String? ?? '',
      lat: double.tryParse(result['lat'] as String? ?? '') ?? 0,
      lon: double.tryParse(result['lon'] as String? ?? '') ?? 0,
    );
  }

  static String _street(Map<String, dynamic> address) {
    final road = address['road'] as String? ?? '';
    return road.isEmpty ? address['city_block'] as String? ?? '' : road;
  }

  static String _city(Map<String, dynamic> address) =>
      address['city'] as String? ??
      address['town'] as String? ??
      address['village'] as String? ??
      address['municipality'] as String? ??
      address['suburb'] as String? ??
      '';

  Future<Result<Object?>> _get(String path, Map<String, String> query) async {
    try {
      final response = await _client.get(
        Uri.https('nominatim.openstreetmap.org', path, query),
        headers: HttpConfig.headers,
      );
      if (response.statusCode != 200) {
        return Result.error(http.ClientException('Nominatim ${response.statusCode}'));
      }
      return Result.ok(jsonDecode(utf8.decode(response.bodyBytes)));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
