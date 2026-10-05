import 'package:candle/ui/import/view_models/distance_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../fakes/fake_location_service.dart';

void main() {
  test('follows the user: the distance to the target', () async {
    final location = FakeLocationService(const Result.ok(LatLng(52.5, 13.4)));
    final viewModel = DistanceViewModel(locationService: location, target: const LatLng(52.51, 13.4));
    await pumpEventQueue();
    expect(viewModel.distance, closeTo(1112, 10));

    location.controller.add(const LatLng(52.505, 13.4));
    await pumpEventQueue();
    expect(viewModel.distance, closeTo(556, 10));
    viewModel.dispose();
  });

  test('without a GPS position there is no distance', () async {
    final location = FakeLocationService(Result.error(Exception('no fix')));
    final viewModel = DistanceViewModel(locationService: location, target: const LatLng(52.51, 13.4));
    await pumpEventQueue();
    expect(viewModel.distance, isNull);
    viewModel.dispose();
  });
}
