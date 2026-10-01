import 'dart:async';

import 'package:candle/data/repositories/geocoding/geocoding_repository.dart';
import 'package:candle/data/repositories/poi/poi_repository.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/domain/models/poi.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Places of one [PoiCategory] around the user, kept sorted by distance
/// while the user walks.
class PoiCategoryViewModel extends ChangeNotifier {
  PoiCategoryViewModel({
    required this.category,
    required this._poiRepository,
    required this._locationService,
    required this._geocodingRepository,
    int? radiusInMeter,
    this.reloadDistanceInMeter = 500,
  }) : radiusInMeter = radiusInMeter ?? category.searchRadiusInMeter {
    load = Command0(_load)..execute();
  }

  final PoiCategory category;
  final int radiusInMeter;
  final int reloadDistanceInMeter;
  final PoiRepository _poiRepository;
  final LocationService _locationService;
  final GeocodingRepository _geocodingRepository;

  late final Command0<void> load;

  LatLng? _location;
  LatLng? get location => _location;

  List<Poi> _pois = [];
  List<Poi> get pois => _pois;

  LatLng? _loadedAt;
  StreamSubscription<LatLng>? _positions;

  int distanceTo(Poi poi) =>
      _location == null ? 0 : calculateDistance(poi.position, _location!).round();

  Future<Result<void>> _load() async {
    final position = _location ?? await _currentPosition();
    if (position == null) return Result.error(Exception('No GPS position available'));
    _location = position;

    final result =
        await _poiRepository.findNearby({category}, position, radiusInMeter: radiusInMeter);
    switch (result) {
      case Ok(:final value):
        _pois = value;
        _loadedAt = position;
        _followPosition();
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        _log.w('Loading POIs failed: $error');
        return Result.error(error);
    }
  }

  Future<LatLng?> _currentPosition() async {
    final result = await _locationService.currentPosition();
    return result is Ok<LatLng> ? result.value : null;
  }

  void _followPosition() {
    _positions ??= _locationService.positions().listen(
          _onPosition,
          onError: (Object e) => _log.w('Position stream error: $e'),
        );
  }

  void _onPosition(LatLng position) {
    _location = position;
    _pois = [..._pois]..sort((a, b) => distanceTo(a).compareTo(distanceTo(b)));
    notifyListeners();

    final loadedAt = _loadedAt;
    if (loadedAt != null &&
        !load.running &&
        calculateDistance(loadedAt, position) > reloadDistanceInMeter) {
      unawaited(load.execute());
    }
  }

  /// Converts a place into an address that can be saved or shared.
  /// Places without a complete OSM address are reverse geocoded.
  Future<LocationAddress> toLocationAddress(
    Poi poi, {
    required String name,
    required String formattedAddress,
  }) async {
    if (!poi.hasAddress) {
      final address = await _geocodingRepository.addressAt(poi.position);
      if (address case Ok(:final value)) {
        return value.copyWith(
            name: name, lat: poi.position.latitude, lon: poi.position.longitude);
      }
    }
    return LocationAddress(
      name: name,
      formattedAddress: formattedAddress,
      street: poi.street,
      number: poi.number,
      zip: poi.zip,
      city: poi.city,
      country: '',
      lat: poi.position.latitude,
      lon: poi.position.longitude,
    );
  }

  @override
  void dispose() {
    unawaited(_positions?.cancel());
    load.dispose();
    super.dispose();
  }
}
