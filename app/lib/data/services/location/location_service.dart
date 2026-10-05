import 'dart:async';
import 'dart:io';

import 'package:candle/utils/result.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Position updates from the platform for the given settings.
typedef PositionSource = Stream<LatLng> Function(LocationSettings settings);

/// Access to the device position. Permissions are requested during onboarding.
///
/// The platform plugin can run only one position stream at a time, and stopping it
/// calls into the system on the main thread. So the whole app shares one stream:
/// screens only listen to it, it keeps running for a while after the last
/// listener left (switching tabs does not stop and restart GPS), and it switches
/// to the foreground service settings while a route is recorded.
class LocationService {
  LocationService({
    PositionSource? source,
    Future<Result<LatLng>> Function()? currentPositionSource,
    Future<Result<double>> Function(Duration timeLimit)? accuracySource,
    DateTime Function()? now,
    this._keepAlive = const Duration(seconds: 20),
    this._maxPositionAge = const Duration(seconds: 30),
  })  : _source = source ?? _platformPositions,
        _currentPositionSource = currentPositionSource ?? _platformCurrentPosition,
        _accuracySource = accuracySource ?? _platformAccuracy,
        _now = now ?? DateTime.now;

  static const _settings = LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5);

  /// How long GPS keeps running after the last listener left.
  final Duration _keepAlive;

  /// A remembered position younger than this is handed out without asking GPS.
  final Duration _maxPositionAge;

  final PositionSource _source;
  final Future<Result<LatLng>> Function() _currentPositionSource;
  final Future<Result<double>> Function(Duration timeLimit) _accuracySource;
  final DateTime Function() _now;

  final _listeners = <_Listener>[];
  StreamSubscription<LatLng>? _platform;
  _Notification? _platformNotification;
  Timer? _stopTimer;
  LatLng? _last;
  DateTime? _lastAt;

  LatLng? get _freshPosition =>
      _lastAt != null && _now().difference(_lastAt!) <= _maxPositionAge ? _last : null;

  Future<Result<LatLng>> currentPosition() async {
    if (_freshPosition case final position?) return Result.ok(position);
    return _currentPositionSource();
  }

  /// Accuracy (radius in meters) of a fresh GPS fix; an error when no fix comes
  /// within [timeLimit], which is typical indoors.
  Future<Result<double>> currentAccuracy({required Duration timeLimit}) => _accuracySource(timeLimit);

  /// Position updates while someone listens; starts with the last position if it is fresh.
  Stream<LatLng> positions() => _listen(null);

  /// Like [positions], but Android keeps delivering them while the screen is off
  /// and shows a notification with [title] and [text] for that time.
  Stream<LatLng> backgroundPositions({required String title, required String text}) =>
      _listen(_Notification(title, text));

  Stream<LatLng> _listen(_Notification? notification) {
    late final _Listener listener;
    final controller = StreamController<LatLng>(
      onListen: () {
        _listeners.add(listener);
        if (_freshPosition case final position?) listener.controller.add(position);
        _update();
      },
      onCancel: () {
        _listeners.remove(listener);
        _update();
        return listener.controller.close();
      },
    );
    listener = _Listener(controller, notification);
    return controller.stream;
  }

  /// Starts, switches or (after [keepAlive]) stops the one platform stream.
  void _update() {
    if (_listeners.isEmpty) {
      _stopTimer ??= Timer(_keepAlive, _stop);
      return;
    }
    _stopTimer?.cancel();
    _stopTimer = null;

    final notification = _listeners.map((l) => l.notification).nonNulls.firstOrNull;
    if (_platform != null && notification == _platformNotification) return;

    unawaited(_platform?.cancel());
    _platformNotification = notification;
    _platform = _source(_settingsFor(notification)).listen(
      (position) {
        _last = position;
        _lastAt = _now();
        for (final listener in List.of(_listeners)) {
          listener.controller.add(position);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        for (final listener in List.of(_listeners)) {
          listener.controller.addError(error, stackTrace);
        }
      },
    );
  }

  void _stop() {
    _stopTimer = null;
    unawaited(_platform?.cancel());
    _platform = null;
    _platformNotification = null;
  }

  static LocationSettings _settingsFor(_Notification? notification) {
    if (notification == null || !Platform.isAndroid) return _settings;
    return AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: _settings.distanceFilter,
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: notification.title,
        notificationText: notification.text,
        enableWakeLock: true,
        setOngoing: true,
        // Default is "ic_launcher", which does not exist in this app: Android then
        // replaces the notification by a generic "Candle is running".
        notificationIcon: const AndroidResource(name: 'ic_notification', defType: 'drawable'),
      ),
    );
  }

  static Stream<LatLng> _platformPositions(LocationSettings settings) =>
      Geolocator.getPositionStream(locationSettings: settings)
          .map((p) => LatLng(p.latitude, p.longitude));

  static Future<Result<double>> _platformAccuracy(Duration timeLimit) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.best, timeLimit: timeLimit),
      );
      return Result.ok(position.accuracy);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  static Future<Result<LatLng>> _platformCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Result.ok(LatLng(position.latitude, position.longitude));
    } on Exception catch (e) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return Result.ok(LatLng(last.latitude, last.longitude));
      return Result.error(e);
    }
  }
}

class _Listener {
  _Listener(this.controller, this.notification);

  final StreamController<LatLng> controller;

  /// Set when the listener records a route and needs the foreground service.
  final _Notification? notification;
}

class _Notification {
  const _Notification(this.title, this.text);

  final String title;
  final String text;

  @override
  bool operator ==(Object other) => other is _Notification && other.title == title && other.text == text;

  @override
  int get hashCode => Object.hash(title, text);
}
