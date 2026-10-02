import 'dart:async';

import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/data/services/share/share_service.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/geo.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// The voice pins, nearest first while the user walks.
class LocationNotesViewModel extends ChangeNotifier {
  LocationNotesViewModel({
    required LocationNoteRepository locationNoteRepository,
    required LocationService locationService,
    required ShareService shareService,
  })  : _pins = locationNoteRepository,
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

  final LocationNoteRepository _pins;
  final LocationService _location;
  final ShareService _share;
  late final List<StreamSubscription<Object?>> _subscriptions;

  late final Command1<void, LocationNote> delete;
  late final Command1<void, LocationNote> share;

  bool _loaded = false;

  /// False until the pins were read the first time.
  bool get loaded => _loaded;

  List<LocationNote> _all = [];
  List<LocationNote> get pins => _all;

  LatLng? _position;
  LatLng? get position => _position;

  /// Meters from the user to [pin], null without a GPS position.
  int? distanceTo(LocationNote pin) =>
      _position == null ? null : calculateDistance(pin.latlng(), _position!).round();

  /// A new, empty pin at the current position; null without a GPS position.
  LocationNote? newPinHere() => _position == null
      ? null
      : LocationNote(name: '', memo: '', lat: _position!.latitude, lon: _position!.longitude);

  void _sort() {
    if (_position != null) {
      _all = [..._all]..sort((a, b) => distanceTo(a)!.compareTo(distanceTo(b)!));
    }
    notifyListeners();
  }

  Future<Result<void>> _delete(LocationNote pin) => _pins.delete(pin.id!);

  Future<Result<void>> _sharePin(LocationNote pin) async {
    try {
      await _share.shareLocationNote(pin);
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
