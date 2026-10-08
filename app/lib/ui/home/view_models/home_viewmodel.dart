import 'dart:async';

import 'package:candle/data/repositories/geocoding/geocoding_repository.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
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

/// A function of the home screen; the user chooses which ones are shown.
enum HomeTile { compass, location, recorder, radar, share, wikipedia, tips, about }

/// The home screen: the address the user is at and the tiles of the main functions.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required GeocodingRepository geocodingRepository,
    required LocationService locationService,
    required SettingsRepository settingsRepository,
    required ShareService shareService,
    this.outdatedDistanceInMeter = 10,
  })  : _geocoding = geocodingRepository,
        _location = locationService,
        _settings = settingsRepository,
        _share = shareService {
    refreshAddress = Command0(_refreshAddress)..execute();
    addressHere = Command0(_addressHere);
    sharePosition = Command1(_sharePosition);
    _settings.addListener(notifyListeners);
    _positions = _location.positions().listen((position) {
      _position = position;
      notifyListeners();
    }, onError: (Object e) => _log.w('Position stream error: $e'));
  }

  final GeocodingRepository _geocoding;
  final LocationService _location;
  final SettingsRepository _settings;
  final ShareService _share;
  final int outdatedDistanceInMeter;
  late final StreamSubscription<LatLng> _positions;

  /// Reads the address at the current position.
  late final Command0<LocationAddress> refreshAddress;

  /// The address at the current position, as a start for a new place.
  late final Command0<LocationAddress> addressHere;

  /// Shares the current position; the argument is the subject of the message.
  late final Command1<void, String Function(LocationAddress)> sharePosition;

  LatLng? _position;
  LocationAddress? _address;

  /// The address last read, null until the first one.
  LocationAddress? get address => _address;

  /// Whether the user has moved away from [address] since it was read.
  bool get addressOutdated =>
      _address == null ||
      (_position != null &&
          calculateDistance(_address!.latlng(), _position!) > outdatedDistanceInMeter);

  List<HomeTile> get tiles => [
        if (_settings.isEnabled(Setting.overviewCompass)) HomeTile.compass,
        if (_settings.isEnabled(Setting.overviewLocation)) HomeTile.location,
        if (_settings.isEnabled(Setting.betaRecording) &&
            _settings.isEnabled(Setting.overviewRecorder))
          HomeTile.recorder,
        if (_settings.isEnabled(Setting.overviewRadar)) HomeTile.radar,
        if (_settings.isEnabled(Setting.overviewShare)) HomeTile.share,
        if (_settings.isEnabled(Setting.overviewWikipedia)) HomeTile.wikipedia,
        if (_settings.isEnabled(Setting.overviewTips)) HomeTile.tips,
        HomeTile.about,
      ];

  Future<Result<LocationAddress>> _addressHere() async {
    final position = switch (await _location.currentPosition()) {
      Ok(:final value) => value,
      Error() => null,
    };
    if (position == null) return Result.error(Exception('No GPS position available'));
    _position = position;
    return _geocoding.addressAt(position);
  }

  Future<Result<LocationAddress>> _refreshAddress() async {
    final result = await _addressHere();
    if (result case Ok(:final value)) {
      _address = value;
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> _sharePosition(String Function(LocationAddress) subject) async {
    final result = await _addressHere();
    if (result case Error(:final error)) return Result.error(error);
    final address = (result as Ok<LocationAddress>).value;
    try {
      await _share.shareLocation(address.copyWith(name: 'MyPosition'),
          subject: subject(address));
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  void dispose() {
    _settings.removeListener(notifyListeners);
    unawaited(_positions.cancel());
    refreshAddress.dispose();
    addressHere.dispose();
    sharePosition.dispose();
    super.dispose();
  }
}
