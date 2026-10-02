import 'package:candle/ui/compass/view_models/heading_compass_viewmodel.dart';
import 'package:candle/utils/geo.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_compass_service.dart';

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
      final viewModel = HeadingCompassViewModel(compassService: compass);

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
}
