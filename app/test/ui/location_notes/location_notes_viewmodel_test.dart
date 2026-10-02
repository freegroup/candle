import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/data/services/share/share_service.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:candle/ui/location_notes/view_models/location_note_edit_viewmodel.dart';
import 'package:candle/ui/location_notes/view_models/location_notes_viewmodel.dart';
import 'package:candle/utils/result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../fakes/fake_location_service.dart';

class _NoShare implements ShareService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late CandleDatabase db;
  late LocationNoteRepository repository;
  late FakeLocationService location;

  setUp(() {
    db = CandleDatabase(NativeDatabase.memory());
    repository = LocationNoteRepository(database: db);
    location = FakeLocationService(const Result.ok(LatLng(1, 8)));
  });
  tearDown(() => db.close());

  LocationNotesViewModel create() => LocationNotesViewModel(
        locationNoteRepository: repository,
        locationService: location,
        shareService: _NoShare(),
      );

  test('lists the pins nearest first and deletes them', () async {
    await repository.save(LocationNote(name: '', memo: 'far', lat: 1.1, lon: 8));
    await repository.save(LocationNote(name: '', memo: 'near', lat: 1.01, lon: 8));
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.pins.map((p) => p.memo), ['near', 'far']);

    await viewModel.delete.execute(viewModel.pins.first);
    await pumpEventQueue();
    expect(viewModel.pins.map((p) => p.memo), ['far']);
    viewModel.dispose();
  });

  test('a new pin is placed at the current position, or not at all without GPS', () async {
    final viewModel = create();
    await pumpEventQueue();
    expect(viewModel.newPinHere()?.latlng(), const LatLng(1, 8));
    viewModel.dispose();

    location.position = Result.error(Exception('no GPS'));
    final withoutGps = create();
    await pumpEventQueue();
    expect(withoutGps.newPinHere(), isNull);
    withoutGps.dispose();
  });

  test('saving twice keeps one pin, at the moved position', () async {
    final viewModel = LocationNoteEditViewModel(
      locationNoteRepository: repository,
      pin: LocationNote(name: '', memo: '', lat: 1, lon: 8),
    );
    viewModel.movePin(const LatLng(2, 9));
    await viewModel.save.execute(' Stairs after the door ');
    await viewModel.save.execute('Stairs after the door');

    final saved = (await repository.watchAll().first).single;
    expect(saved.memo, 'Stairs after the door');
    expect(saved.latlng(), const LatLng(2, 9));
  });
}
