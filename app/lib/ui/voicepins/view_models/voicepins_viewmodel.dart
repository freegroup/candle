import 'dart:async';

import 'package:candle/data/repositories/voicepins/voicepin_repository.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/data/services/share/share_service.dart';
import 'package:candle/domain/models/voicepin.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// The voice pins, nearest first while the user walks.
class VoicePinsViewModel extends ChangeNotifier {
  VoicePinsViewModel({
    required VoicePinRepository voicePinRepository,
    required LocationService locationService,
    required ShareService shareService,
  })  : _pins = voicePinRepository,
        _location = locationService,
        _share = shareService {
    delete = Command1(_delete);
    share = Command1(_sharePin);
    _subscriptions = [
      _pins.watchAll().listen((all) {
        _all = all;
        _loaded = true;
        _sort();
      }, onError: (Object e) => _log.w('Loading voice pins failed: $e')),
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

  final VoicePinRepository _pins;
  final LocationService _location;
  final ShareService _share;
  late final List<StreamSubscription<Object?>> _subscriptions;

  late final Command1<void, VoicePin> delete;
  late final Command1<void, VoicePin> share;

  bool _loaded = false;

  /// False until the pins were read the first time.
  bool get loaded => _loaded;

  List<VoicePin> _all = [];
  List<VoicePin> get pins => _all;

  LatLng? _position;
  LatLng? get position => _position;

  /// Meters from the user to [pin], null without a GPS position.
  int? distanceTo(VoicePin pin) =>
      _position == null ? null : calculateDistance(pin.latlng(), _position!).round();

  /// A new, empty pin at the current position; null without a GPS position.
  VoicePin? newPinHere() => _position == null
      ? null
      : VoicePin(name: '', memo: '', lat: _position!.latitude, lon: _position!.longitude);

  void _sort() {
    if (_position != null) {
      _all = [..._all]..sort((a, b) => distanceTo(a)!.compareTo(distanceTo(b)!));
    }
    notifyListeners();
  }

  Future<Result<void>> _delete(VoicePin pin) => _pins.delete(pin.id!);

  Future<Result<void>> _sharePin(VoicePin pin) async {
    try {
      await _share.shareVoicePin(pin);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    delete.dispose();
    share.dispose();
    super.dispose();
  }
}
