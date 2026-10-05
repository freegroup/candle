import 'dart:async';

import 'package:candle/config/app_config.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/data/services/overpass/overpass_client.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

/// Tells whether the user is probably inside a building (or has poor GPS
/// reception, which looks the same); directions are unreliable then.
///
/// Uses the accuracy of a fresh GPS fix and the building outlines of
/// OpenStreetMap around the user; the limits are in [IndoorConfig].
class IndoorRepository {
  IndoorRepository({required LocationService locationService, required OverpassClient overpassClient})
      : _location = locationService,
        _overpass = overpassClient;

  final LocationService _location;
  final OverpassClient _overpass;

  Future<bool> isProbablyIndoors() async {
    // 1. Poor or no GPS reception: typical indoors, and the directions are unreliable anyway.
    final accuracy = await _accuracy();
    if (accuracy == null || accuracy > IndoorConfig.poorAccuracy) return true;

    // 2. Inside a building outline, at least IndoorConfig.wallInset away from its walls.
    final result = await _location.currentPosition();
    if (result is Ok<LatLng>) {
      final position = result.value;
      for (final buildingOutline in await _buildingsAround(position)) {
        if (isInsidePolygon(position, buildingOutline, inset: IndoorConfig.wallInset)) return true;
      }
    }

    // 3. Outside every outline, or right at a wall (e.g. on the pavement next to the
    //    facade): outdoors.
    return false;
  }

  /// Accuracy in meters of a fresh GPS fix, null when none comes in time.
  Future<double?> _accuracy() async =>
      switch (await _location.currentAccuracy(timeLimit: IndoorConfig.fixTimeout)) {
        Ok(:final value) => value,
        Error() => null,
      };

  /// The outlines of the buildings around [position]; none when the map data does not come.
  Future<List<List<LatLng>>> _buildingsAround(LatLng position) async {
    final query = '[out:json][timeout:${IndoorConfig.mapTimeout.inSeconds}];'
        'way(around:${IndoorConfig.buildingSearchRadius},${position.latitude},${position.longitude})[building];'
        'out geom;';
    try {
      return switch (await _overpass.query(query).timeout(IndoorConfig.mapTimeout)) {
        Ok(:final value) => [for (final building in value) building.geometry],
        Error() => const [],
      };
    } on TimeoutException {
      return const [];
    }
  }
}
