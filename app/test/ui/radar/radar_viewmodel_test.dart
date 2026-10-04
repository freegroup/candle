import 'package:candle/domain/models/poi.dart';
import 'package:candle/ui/radar/view_models/radar_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../fakes/fake_compass_service.dart';
import '../../fakes/fake_location_service.dart';
import '../../fakes/fake_poi_repository.dart';

const here = LatLng(52.5163, 13.3777);
const north = Poi(id: 1, kind: PoiKind.named, name: 'North', position: LatLng(52.5200, 13.3777));
const northNear =
    Poi(id: 2, kind: PoiKind.named, name: 'North near', position: LatLng(52.5170, 13.3780));
const east = Poi(id: 3, kind: PoiKind.named, name: 'East', position: LatLng(52.5163, 13.3900));
// 5° west of north: must be found when pointing north (wrap-around at 0°/360°)
const northWest =
    Poi(id: 4, kind: PoiKind.named, name: 'North west', position: LatLng(52.5190, 13.3772));

void main() {
  late FakePoiRepository repository;
  late FakeLocationService location;
  late FakeCompassService compass;

  RadarViewModel create() => RadarViewModel(
        poiRepository: repository,
        locationService: location,
        compassService: compass,
      );

  setUp(() {
    repository = FakePoiRepository(const Result.ok([northNear, northWest, north, east]));
    location = FakeLocationService(const Result.ok(here));
    compass = FakeCompassService();
  });

  test('loads all categories except crossings', () async {
    final viewModel = create();
    await pumpEventQueue();

    expect(viewModel.load.completed, isTrue);
    expect(repository.lastCategories, isNot(contains(PoiCategory.crossings)));
    expect(repository.lastCategories, contains(PoiCategory.cafes));
    viewModel.dispose();
  });

  test('shows the places of the direction the phone points to', () async {
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.direction, isNull);
    expect(viewModel.poisInDirection, isEmpty);

    compass.headingController.add(355); // within ±10° of north
    await pumpEventQueue();
    expect(viewModel.snappedDirection, 0);
    expect(viewModel.poisInDirection, [northNear, northWest, north]);

    compass.headingController.add(95);
    await pumpEventQueue();
    expect(viewModel.direction, 90);
    expect(viewModel.poisInDirection, [east]);
    viewModel.dispose();
  });

  test('keeps the last direction between two snap points', () async {
    final viewModel = create();
    await pumpEventQueue();

    compass.headingController.add(2);
    await pumpEventQueue();
    compass.headingController.add(20);
    await pumpEventQueue();

    expect(viewModel.snappedDirection, isNull);
    expect(viewModel.direction, 0);
    expect(viewModel.poisInDirection, hasLength(3));
    viewModel.dispose();
  });

  test('reloads after walking 500 m', () async {
    final viewModel = create();
    await pumpEventQueue();

    location.controller.add(const LatLng(52.5300, 13.3777));
    await pumpEventQueue();
    expect(repository.calls, 2);
    viewModel.dispose();
  });

  test('covered, it keeps listening but updates its list only when on top again', () async {
    final viewModel = create();
    await pumpEventQueue();
    compass.headingController.add(0);
    await pumpEventQueue();
    expect(viewModel.direction, 0);

    viewModel.onCovered();
    compass.headingController.add(90);
    location.controller.add(const LatLng(52.5300, 13.3777));
    await pumpEventQueue();
    expect(compass.headingController.hasListener, isTrue);
    expect(viewModel.direction, 0);
    expect(repository.calls, 1);

    viewModel.onUncovered();
    await pumpEventQueue();
    expect(viewModel.direction, 90);
    expect(repository.calls, 2);
    viewModel.dispose();
  });

  test('warns only after the phone has been tilted for a while', () async {
    const delay = Duration(milliseconds: 60);
    final viewModel = RadarViewModel(
      poiRepository: repository,
      locationService: location,
      compassService: compass,
      tiltWarningDelay: delay,
    );
    Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

    compass.horizontalController.add(false);
    await wait(30);
    compass.horizontalController.add(true); // short wobble: no warning
    await wait(30);
    compass.horizontalController.add(false);
    await wait(30);
    expect(viewModel.isTilted, isFalse);

    await wait(60);
    expect(viewModel.isTilted, isTrue);

    compass.horizontalController.add(true);
    await wait(90);
    expect(viewModel.isTilted, isFalse);
    viewModel.dispose();
  });
}
