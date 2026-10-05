import 'dart:async';

import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

class FakeLocationService implements LocationService {
  FakeLocationService(this.position);

  Result<LatLng> position;

  /// Accuracy in meters of a fresh fix; good (outdoors) by default.
  Result<double> accuracy = const Result.ok(5);

  // Lives as long as the test; closing is not needed for a broadcast fake.
  // ignore: close_sinks
  final controller = StreamController<LatLng>.broadcast();

  @override
  Future<Result<LatLng>> currentPosition() async => position;

  @override
  Future<Result<double>> currentAccuracy({required Duration timeLimit}) async => accuracy;

  @override
  Stream<LatLng> positions() => controller.stream;

  @override
  Stream<LatLng> backgroundPositions({required String title, required String text}) =>
      controller.stream;
}
