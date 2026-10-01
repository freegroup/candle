import 'package:candle/ui/compass/view_models/compass_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../fakes/fake_compass_service.dart';
import '../../fakes/fake_location_service.dart';

void main() {
  test('snaps to the eight compass directions, also around north', () {
    expect(snapToDirection(0), 0);
    expect(snapToDirection(355), 0);
    expect(snapToDirection(10), 0);
    expect(snapToDirection(11), isNull);
    expect(snapToDirection(98), 90);
    expect(snapToDirection(315), 315);
  });

  test('warns about a tilted phone only after a while', () {
    fakeAsync((async) {
      final compass = FakeCompassService();
      final viewModel = CompassViewModel(compassService: compass);

      compass.horizontalController.add(false);
      async.elapse(const Duration(seconds: 2));
      expect(viewModel.isTilted, isFalse);
      async.elapse(const Duration(seconds: 2));
      expect(viewModel.isTilted, isTrue);

      // a short moment flat does not end the warning
      compass.horizontalController.add(true);
      async.elapse(const Duration(seconds: 1));
      compass.horizontalController.add(false);
      async.elapse(const Duration(seconds: 5));
      expect(viewModel.isTilted, isTrue);

      compass.horizontalController.add(true);
      async.elapse(const Duration(seconds: 4));
      expect(viewModel.isTilted, isFalse);
      viewModel.dispose();
    });
  });

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
