import 'dart:async';

import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

class FakeLocationService implements LocationService {
  FakeLocationService(this.position);

  Result<LatLng> position;

  // Lives as long as the test; closing is not needed for a broadcast fake.
  // ignore: close_sinks
  final controller = StreamController<LatLng>.broadcast();

  @override
  Future<Result<LatLng>> currentPosition() async => position;

  @override
  Stream<LatLng> positions() => controller.stream;
}
