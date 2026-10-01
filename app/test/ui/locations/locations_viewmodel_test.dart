import 'package:candle/data/repositories/locations/location_repository.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/data/services/share/share_service.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/ui/locations/view_models/address_search_viewmodel.dart';
import 'package:candle/ui/locations/view_models/location_edit_viewmodel.dart';
import 'package:candle/ui/locations/view_models/locations_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../fakes/fake_geocoding_repository.dart';
import '../../fakes/fake_location_service.dart';

LocationAddress _place(String name, double lat, {int? id}) => LocationAddress(
      id: id,
      name: name,
      formattedAddress: '$name street',
      street: '',
      number: '',
      zip: '',
      city: '',
      country: '',
      lat: lat,
      lon: 8,
    );

class _NoShare implements ShareService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late CandleDatabase db;
  late LocationRepository repository;
  late FakeLocationService location;
  late FakeGeocodingRepository geocoding;

  setUp(() {
    db = CandleDatabase(NativeDatabase.memory());
    repository = LocationRepository(database: db);
    location = FakeLocationService(const Result.ok(LatLng(1.0, 8)));
    geocoding = FakeGeocodingRepository();
  });
  tearDown(() => db.close());

  LocationsViewModel create() => LocationsViewModel(
        locationRepository: repository,
        geocodingRepository: geocoding,
        locationService: location,
        shareService: _NoShare(),
      );

  group('LocationsViewModel', () {
    test('lists the places nearest first and re-sorts while walking', () async {
      await repository.save(_place('far', 1.1));
      await repository.save(_place('near', 1.01));
      final viewModel = create();
      await pumpEventQueue();

      expect(viewModel.loaded, isTrue);
      expect(viewModel.locations.map((l) => l.name), ['near', 'far']);
      expect(viewModel.distanceTo(viewModel.locations.first), closeTo(1110, 10));

      location.controller.add(const LatLng(1.1, 8));
      await pumpEventQueue();
      expect(viewModel.locations.map((l) => l.name), ['far', 'near']);
      viewModel.dispose();
    });

    test('deleting removes the place from the list', () async {
      await repository.save(_place('home', 1));
      final viewModel = create();
      await pumpEventQueue();

      await viewModel.delete.execute(viewModel.locations.single);
      await pumpEventQueue();
      expect(viewModel.locations, isEmpty);
      viewModel.dispose();
    });

    test('a new place starts with the address of the current position', () async {
      geocoding.address = _place('', 1);
      final viewModel = create();
      await viewModel.addressHere.execute();
      expect((viewModel.addressHere.result as Ok<LocationAddress>).value.formattedAddress,
          ' street');

      geocoding.address = null;
      await viewModel.addressHere.execute();
      expect(viewModel.addressHere.error, isTrue);
      viewModel.dispose();
    });
  });

  group('LocationEditViewModel', () {
    test('adds a new place with the trimmed name', () async {
      final viewModel =
          LocationEditViewModel(locationRepository: repository, location: _place('', 1));
      expect(viewModel.isUpdate, isFalse);
      await viewModel.save.execute('  Bakery ');
      expect((await repository.watchAll().first).single.name, 'Bakery');
    });

    test('a new address keeps id and name of the edited place', () async {
      final id = (await repository.save(_place('Home', 1)) as Ok<int>).value;
      final viewModel =
          LocationEditViewModel(locationRepository: repository, location: _place('Home', 1, id: id));
      expect(viewModel.isUpdate, isTrue);

      viewModel.changeAddress(_place('Other street', 2));
      expect(viewModel.location.id, id);
      expect(viewModel.location.lat, 2);
      await viewModel.save.execute('Home');

      final saved = (await repository.watchAll().first).single;
      expect(saved.id, id);
      expect(saved.formattedAddress, 'Other street street');
    });
  });

  group('AddressSearchViewModel', () {
    test('searches once the user pauses typing and ignores single letters', () {
      fakeAsync((async) {
        geocoding.searchResults = [_place('Main street', 1)];
        final viewModel = AddressSearchViewModel(geocodingRepository: geocoding, languageCode: 'de');

        viewModel.search('M');
        async.elapse(const Duration(seconds: 2));
        expect(viewModel.results, isEmpty);

        viewModel.search('Ma');
        viewModel.search('Main');
        async.elapse(const Duration(milliseconds: 500));
        expect(viewModel.results, isEmpty);
        async.elapse(const Duration(seconds: 1));
        expect(viewModel.results.single.name, 'Main street');
        viewModel.dispose();
      });
    });
  });
}
