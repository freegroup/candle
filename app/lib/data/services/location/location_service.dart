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
}
