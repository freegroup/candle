import 'package:candle/ui/compass/view_models/target_compass_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../fakes/fake_compass_service.dart';
import '../../fakes/fake_location_service.dart';

void main() {
  test('the target compass tells direction and distance to the target', () async {
    final compass = FakeCompassService();
    final location = FakeLocationService(const Result.ok(LatLng(52.5, 13.4)));
    // ~1.1 km north of the user
    final viewModel = TargetCompassViewModel(
      compassService: compass,
      locationService: location,
      target: const LatLng(52.51, 13.4),
      targetName: 'Bakery',
    );
    await pumpEventQueue();
    expect(viewModel.distance, closeTo(1112, 10));

    compass.headingController.add(0);
    await pumpEventQueue();
    expect(viewModel.isAligned, isTrue);

    compass.headingController.add(90); // phone points east, target is to the left
    await pumpEventQueue();
    expect(viewModel.isAligned, isFalse);
    expect(viewModel.targetHeading, 90);
    expect(viewModel.snappedDirection, 90);
    viewModel.dispose();
  });
}
