import 'package:candle/domain/models/poi.dart';
import 'package:candle/ui/explore/view_models/poi_category_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../fakes/fake_geocoding_repository.dart';
import '../../fakes/fake_location_service.dart';
import '../../fakes/fake_poi_repository.dart';

const here = LatLng(52.5163, 13.3777);
const near = Poi(id: 1, kind: PoiKind.named, name: 'Near', position: LatLng(52.5170, 13.3777));
const far = Poi(id: 2, kind: PoiKind.named, name: 'Far', position: LatLng(52.5200, 13.3777));

void main() {
  late FakePoiRepository repository;
  late FakeLocationService location;

  PoiCategoryViewModel create() => PoiCategoryViewModel(
        category: PoiCategory.cafes,
        poiRepository: repository,
        locationService: location,
        geocodingRepository: FakeGeocodingRepository(),
      );

  setUp(() {
    repository = FakePoiRepository(const Result.ok([near, far]));
    location = FakeLocationService(const Result.ok(here));
  });

  test('loads places on creation', () async {
    final viewModel = create();
    expect(viewModel.load.running, isTrue);
    await pumpEventQueue();

    expect(viewModel.load.completed, isTrue);
    expect(viewModel.pois, [near, far]);
    expect(viewModel.distanceTo(near), 78);
  });

  test('reports an error without GPS position', () async {
    location.position = Result.error(Exception('no gps'));
    final viewModel = create();
    await pumpEventQueue();

    expect(viewModel.load.error, isTrue);
    expect(repository.calls, 0);
  });

  test('re-sorts while walking and reloads after 500 m', () async {
    final viewModel = create();
    await pumpEventQueue();

    location.controller.add(const LatLng(52.5199, 13.3777)); // next to "Far"
    await pumpEventQueue();
    expect(viewModel.pois.first, far);
    expect(repository.calls, 1);

    location.controller.add(const LatLng(52.5300, 13.3777)); // > 500 m away
    await pumpEventQueue();
    expect(repository.calls, 2);
    viewModel.dispose();
  });

  test('retry after an error loads again', () async {
    repository.result = Result.error(Exception('down'));
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.load.error, isTrue);

    repository.result = const Result.ok([near]);
    await viewModel.load.execute();
    expect(viewModel.pois, [near]);
  });
}
