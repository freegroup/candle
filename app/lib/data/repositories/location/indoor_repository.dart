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
/// Combines the accuracy of a fresh GPS fix with the building outlines of
/// OpenStreetMap, weighted and compared with a threshold from [IndoorConfig].
class IndoorRepository {
  IndoorRepository({required LocationService locationService, required OverpassClient overpassClient})
      : _location = locationService,
        _overpass = overpassClient;

  final LocationService _location;
  final OverpassClient _overpass;

  Future<bool> isProbablyIndoors() async {
    final (accuracy, inBuilding) = await (_accuracyScore(), _insideBuilding()).wait;
    final probability = inBuilding == null
        ? accuracy
        : IndoorConfig.accuracyWeight * accuracy +
            IndoorConfig.buildingWeight * (inBuilding ? 1 : 0);
    return probability >= IndoorConfig.threshold;
  }

  /// 0 for a good fix, 1 for a bad one or none at all.
  Future<double> _accuracyScore() async {
    final result = await _location.currentAccuracy(timeLimit: IndoorConfig.fixTimeout);
    if (result case Ok(:final value)) {
      return ((value - IndoorConfig.goodAccuracy) /
              (IndoorConfig.badAccuracy - IndoorConfig.goodAccuracy))
          .clamp(0.0, 1.0);
    }
    return 1;
  }

  /// Whether the last position lies inside a building outline; null when unknown.
  Future<bool?> _insideBuilding() async {
    final position = await _location.currentPosition();
    if (position is! Ok<LatLng>) return null;
    final here = position.value;
    final query = '[out:json][timeout:${IndoorConfig.mapTimeout.inSeconds}];'
        'way(around:${IndoorConfig.buildingSearchRadius},${here.latitude},${here.longitude})[building];'
        'out geom;';
    try {
      return switch (await _overpass.query(query).timeout(IndoorConfig.mapTimeout)) {
        Ok(:final value) => value.any((building) => isInsidePolygon(here, building.geometry)),
        Error() => null,
      };
    } on TimeoutException {
      return null;
    }
  }
}
