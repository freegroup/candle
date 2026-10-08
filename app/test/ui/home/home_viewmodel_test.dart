import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/share/share_service.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/ui/home/view_models/home_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../fakes/fake_geocoding_repository.dart';
import '../../fakes/fake_location_service.dart';

class _NoShare implements ShareService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _here = LatLng(1, 8);
final _address = LocationAddress(
    name: '', formattedAddress: 'Main Street 1', street: 'Main Street', number: '1',
    zip: '', city: 'Town', country: '', lat: 1, lon: 8);

void main() {
  late SettingsRepository settings;
  late FakeGeocodingRepository geocoding;
  late FakeLocationService location;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
    geocoding = FakeGeocodingRepository()..address = _address;
    location = FakeLocationService(const Result.ok(_here));
  });

  HomeViewModel create() => HomeViewModel(
        geocodingRepository: geocoding,
        locationService: location,
        settingsRepository: settings,
        shareService: _NoShare(),
      );

  test('the tips tile comes before the information tile and can be hidden', () async {
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.tiles.sublist(viewModel.tiles.length - 2), [HomeTile.tips, HomeTile.about]);

    await settings.setEnabled(Setting.overviewTips, false);
    expect(viewModel.tiles, isNot(contains(HomeTile.tips)));
    viewModel.dispose();
  });

  test('shows the address of the current position until the user walks away', () async {
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.address?.street, 'Main Street');
    expect(viewModel.addressOutdated, isFalse);

    location.controller.add(const LatLng(1.001, 8)); // ~110 m
    await pumpEventQueue();
    expect(viewModel.addressOutdated, isTrue);
    viewModel.dispose();
  });

  test('offers a retry when the address cannot be read', () async {
    geocoding.address = null;
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.address, isNull);
    expect(viewModel.refreshAddress.error, isTrue);
    viewModel.dispose();
  });

  test('shows the tiles the user chose', () async {
    final viewModel = create();
    expect(viewModel.tiles, isNot(contains(HomeTile.recorder)));
    expect(viewModel.tiles.last, HomeTile.about);

    await settings.setEnabled(Setting.betaRecording, true);
    await settings.setEnabled(Setting.overviewCompass, false);
    expect(viewModel.tiles, contains(HomeTile.recorder));
    expect(viewModel.tiles, isNot(contains(HomeTile.compass)));
    viewModel.dispose();
  });
}
