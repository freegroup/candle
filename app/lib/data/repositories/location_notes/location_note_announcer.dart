import 'dart:async';

import 'package:candle/config/app_config.dart';
import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/utils/geo.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Reports the location notes the user reaches, app-wide while Candle is visible:
/// always, or only during a navigation if the user turned [Setting.locationNotesAlways] off.
///
/// A note comes once, and again after the user was [LocationNoteConfig.resetDistance]
/// away from it or when a new navigation starts. Position updates run only while
/// notes can be reported.
class LocationNoteAnnouncer {
  LocationNoteAnnouncer({
    required LocationNoteRepository locationNoteRepository,
    required LocationService locationService,
    required SettingsRepository settingsRepository,
  })  : _repository = locationNoteRepository,
        _location = locationService,
        _settings = settingsRepository {
    _settings.addListener(_update);
    _lifecycle = AppLifecycleListener(onStateChange: (state) {
      _visible = _isVisible(state);
      _update();
    });
    _update();
  }

  final LocationNoteRepository _repository;
  final LocationService _location;
  final SettingsRepository _settings;
  late final AppLifecycleListener _lifecycle;

  final _reached = StreamController<LocationNote>.broadcast();

  /// A location note the user just reached.
  Stream<LocationNote> get reached => _reached.stream;

  bool _visible = _isVisible(WidgetsBinding.instance.lifecycleState);
  int _navigations = 0;
  int _pauses = 0;
  StreamSubscription<LatLng>? _positions;
  StreamSubscription<List<LocationNote>>? _notesSubscription;
  List<LocationNote>? _notes;
  LatLng? _position;

  /// After a pause the notes around the user count as heard instead of being reported.
  bool _quiet = false;

  /// Positions of the notes already reported, by note id.
  final _announced = <int?, LatLng>{};

  /// A navigation started: notes are reported (also with [Setting.locationNotesAlways]
  /// off), and notes reported before come again.
  void startNavigation() {
    _navigations++;
    _announced.clear();
    _update();
  }

  void stopNavigation() {
    _navigations--;
    _update();
  }

  /// No notes are reported until [resume], e.g. while the user types a note.
  void pause() {
    _pauses++;
    _update();
  }

  /// Ends a [pause]. Notes around the user then count as heard, so a note just
  /// added here does not report itself; they come again after the user was away.
  void resume() {
    _pauses--;
    if (_pauses == 0) _quiet = true;
    _update();
  }

  static bool _isVisible(AppLifecycleState? state) =>
      state != AppLifecycleState.hidden &&
      state != AppLifecycleState.paused &&
      state != AppLifecycleState.detached;

  bool get _active =>
      _visible &&
      _pauses == 0 &&
      (_navigations > 0 || _settings.isEnabled(Setting.locationNotesAlways));

  void _update() {
    if (_active == (_positions != null)) return;
    if (_active) {
      _notesSubscription = _repository.watchAll().listen((notes) {
        _notes = notes;
        _check();
      }, onError: _logError);
      _positions = _location.positions().listen((position) {
        _position = position;
        _check();
      }, onError: _logError);
    } else {
      unawaited(_positions?.cancel());
      unawaited(_notesSubscription?.cancel());
      _positions = null;
      _notesSubscription = null;
      _notes = null;
      _position = null;
    }
  }

  void _check() {
    final notes = _notes;
    final position = _position;
    if (notes == null || position == null) return;
    _announced.removeWhere(
        (_, note) => calculateDistance(note, position) >= LocationNoteConfig.resetDistance);
    if (_quiet) {
      _quiet = false;
      for (final note in notes) {
        if (calculateDistance(note.latlng(), position) < LocationNoteConfig.announceDistance) {
          _announced[note.id] = note.latlng();
        }
      }
      return;
    }
    final nearest = notes
        .where((note) =>
            !_announced.containsKey(note.id) &&
            calculateDistance(note.latlng(), position) < LocationNoteConfig.announceDistance)
        .fold<LocationNote?>(
            null,
            (best, note) => best == null ||
                    calculateDistance(note.latlng(), position) <
                        calculateDistance(best.latlng(), position)
                ? note
                : best);
    if (nearest == null) return;
    _announced[nearest.id] = nearest.latlng();
    _reached.add(nearest);
  }

  void _logError(Object e) => _log.w('Location note announcer: $e');

  void dispose() {
    _settings.removeListener(_update);
    _lifecycle.dispose();
    unawaited(_positions?.cancel());
    unawaited(_notesSubscription?.cancel());
    unawaited(_reached.close());
  }
}
