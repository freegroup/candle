import 'dart:async';

import 'package:candle/data/repositories/geocoding/geocoding_repository.dart';
import 'package:candle/data/repositories/locations/location_repository.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/data/services/share/share_service.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// The saved places, nearest first while the user walks.
class LocationsViewModel extends ChangeNotifier {
  LocationsViewModel({
    required LocationRepository locationRepository,
    required GeocodingRepository geocodingRepository,
    required LocationService locationService,
    required ShareService shareService,
  })  : _locations = locationRepository,
        _geocoding = geocodingRepository,
        _location = locationService,
        _share = shareService {
    delete = Command1(_delete);
    share = Command1(_shareLocation);
    addressHere = Command0(_addressHere);
    _subscriptions = [
      _locations.watchAll().listen((all) {
        _all = all;
        _loaded = true;
        _sort();
      }, onError: (Object e) => _log.w('Loading places failed: $e')),
      _location.positions().listen((position) {
        _position = position;
        _sort();
      }, onError: (Object e) => _log.w('Position stream error: $e')),
    ];
    unawaited(_location.currentPosition().then((result) {
      if (result case Ok(:final value) when _position == null) {
        _position = value;
        _sort();
      }
    }));
  }

  final LocationRepository _locations;
  final GeocodingRepository _geocoding;
  final LocationService _location;
  final ShareService _share;
  late final List<StreamSubscription<Object?>> _subscriptions;

  late final Command1<void, LocationAddress> delete;
  late final Command1<void, LocationAddress> share;

  /// The address of the current position, as a start for a new place.
  late final Command0<LocationAddress> addressHere;

  bool _loaded = false;

  /// False until the places were read the first time.
  bool get loaded => _loaded;

  List<LocationAddress> _all = [];
  List<LocationAddress> get locations => _all;

  LatLng? _position;
  LatLng? get position => _position;

  /// Meters from the user to [location], null without a GPS position.
  int? distanceTo(LocationAddress location) =>
      _position == null ? null : calculateDistance(location.latlng(), _position!).round();

  void _sort() {
    if (_position != null) {
      _all = [..._all]..sort((a, b) => distanceTo(a)!.compareTo(distanceTo(b)!));
    }
    notifyListeners();
  }

  Future<Result<void>> _delete(LocationAddress location) => _locations.delete(location.id!);

  Future<Result<void>> _shareLocation(LocationAddress location) async {
    try {
      await _share.shareLocation(location);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<LocationAddress>> _addressHere() async {
    final position = _position ?? switch (await _location.currentPosition()) {
      Ok(:final value) => value,
      Error() => null,
    };
    if (position == null) return Result.error(Exception('No GPS position available'));
    return _geocoding.addressAt(position);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    delete.dispose();
    share.dispose();
    addressHere.dispose();
    super.dispose();
  }
}
