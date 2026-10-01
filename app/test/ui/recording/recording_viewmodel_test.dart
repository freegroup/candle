import 'package:candle/data/repositories/recording/recording_repository.dart';
import 'package:candle/data/repositories/routes/route_repository.dart';
import 'package:candle/data/services/permissions/permission_service.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/ui/recording/view_models/recording_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../fakes/fake_compass_service.dart';
import '../../fakes/fake_location_service.dart';

class _FakePermissions implements PermissionService {
  int notificationRequests = 0;

  @override
  Future<void> requestNotifications() async => notificationRequests++;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _notification = (title: 'title', text: 'text');

void main() {
  late CandleDatabase db;
  late RouteRepository routes;
  late FakeLocationService location;
  late RecordingRepository recording;
  late RecordingViewModel viewModel;
  late int vibrations;
  late _FakePermissions permissions;

  setUp(() {
    db = CandleDatabase(NativeDatabase.memory());
    routes = RouteRepository(database: db);
    location = FakeLocationService(const Result.ok(LatLng(0, 0)));
    vibrations = 0;
    permissions = _FakePermissions();
    recording = RecordingRepository(
      routeRepository: routes,
      locationService: location,
      onPointRecorded: () => vibrations++,
    );
    viewModel = RecordingViewModel(
      recordingRepository: recording,
      routeRepository: routes,
      compassService: FakeCompassService(),
      permissionService: permissions,
    );
  });

  tearDown(() async {
    viewModel.dispose();
    recording.dispose();
    await db.close();
  });

  Future<void> walk(List<double> latitudes) async {
    for (final lat in latitudes) {
      location.controller.add(LatLng(lat, 8));
      await pumpEventQueue();
    }
  }

  test('records the walked positions into a new route and keeps it on save', () async {
    await viewModel.start.execute((' Walk ', _notification));
    expect(viewModel.isRecording, isTrue);
    expect(permissions.notificationRequests, 1);

    await walk([1, 2, 3]);
    expect(viewModel.route?.name, 'Walk');
    expect(viewModel.route?.points.map((p) => p.coordinate.latitude), [1, 2, 3]);
    expect(vibrations, 3);

    await viewModel.stop.execute(true);
    expect(viewModel.isRecording, isFalse);
    await walk([4]);

    final saved = await routes.watchAll().first;
    expect(saved.single.points.map((p) => p.coordinate.latitude), [1, 2, 3]);
  });

  test('discarding deletes the recorded route', () async {
    await viewModel.start.execute(('Walk', _notification));
    await walk([1]);

    await viewModel.stop.execute(false);
    expect(await routes.watchAll().first, isEmpty);
  });

  test('recording an existing route name starts that route anew', () async {
    await routes.save(Route(name: 'Walk', points: []));
    await viewModel.start.execute(('Walk', _notification));
    await walk([5]);

    final all = await routes.watchAll().first;
    expect(all.single.points.map((p) => p.coordinate.latitude), [5]);
  });

  test('the recording continues when the screen is closed', () async {
    await viewModel.start.execute(('Walk', _notification));
    viewModel.dispose();
    await walk([1]);

    viewModel = RecordingViewModel(
      recordingRepository: recording,
      routeRepository: routes,
      compassService: FakeCompassService(),
      permissionService: permissions,
    );
    await pumpEventQueue();
    expect(viewModel.isRecording, isTrue);
    expect(viewModel.route?.points, hasLength(1));
  });
}
