import 'package:candle/data/repositories/routes/route_repository.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/ui/routes/view_models/routes_viewmodel.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CandleDatabase db;
  late RouteRepository repository;

  setUp(() {
    db = CandleDatabase(NativeDatabase.memory());
    repository = RouteRepository(database: db);
  });
  tearDown(() => db.close());

  test('lists the routes by name and deletes them', () async {
    await repository.save(Route(name: 'Work', points: []));
    await repository.save(Route(name: 'Bakery', points: []));
    final viewModel = RoutesViewModel(routeRepository: repository);
    expect(viewModel.routes, isNull);
    await pumpEventQueue();
    expect(viewModel.routes!.map((r) => r.name), ['Bakery', 'Work']);

    await viewModel.delete.execute(viewModel.routes!.first);
    await pumpEventQueue();
    expect(viewModel.routes!.map((r) => r.name), ['Work']);
    viewModel.dispose();
  });

  test('renaming fails when another route has the name', () async {
    await repository.save(Route(name: 'Work', points: []));
    await repository.save(Route(name: 'Bakery', points: []));
    final work = (await repository.watchAll().first).last;
    final viewModel = RouteEditViewModel(routeRepository: repository, route: work);

    await viewModel.rename.execute('Bakery');
    expect(viewModel.rename.error, isTrue);

    await viewModel.rename.execute(' Office ');
    expect(viewModel.rename.completed, isTrue);
    expect((await repository.watchAll().first).map((r) => r.name), ['Bakery', 'Office']);
  });
}
