import 'dart:io';

import 'package:candle/utils/result.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Access to the device position. Permissions are requested during onboarding.
class LocationService {
  static const _settings = LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5);

  Future<Result<LatLng>> currentPosition() async {
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

  /// Position updates while someone listens; GPS is released on cancel.
  Stream<LatLng> positions() => Geolocator.getPositionStream(locationSettings: _settings)
      .map((p) => LatLng(p.latitude, p.longitude));

  /// Like [positions], but Android keeps delivering them while the screen is off
  /// and shows a notification with [title] and [text] for that time.
  Stream<LatLng> backgroundPositions({required String title, required String text}) {
    final settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: _settings.distanceFilter,
            foregroundNotificationConfig: ForegroundNotificationConfig(
              notificationTitle: title,
              notificationText: text,
              enableWakeLock: true,
              setOngoing: true,
            ),
          )
        : _settings;
    return Geolocator.getPositionStream(locationSettings: settings)
        .map((p) => LatLng(p.latitude, p.longitude));
  }
}
