import 'dart:async';

import 'package:candle/data/repositories/routes/route_repository.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// The recorded routes, ordered by name.
class RoutesViewModel extends ChangeNotifier {
  RoutesViewModel({required RouteRepository routeRepository}) : _routes = routeRepository {
    delete = Command1(_delete);
    _subscription = _routes.watchAll().listen((routes) {
      _all = routes;
      notifyListeners();
    }, onError: (Object e) => _log.w('Loading routes failed: $e'));
  }

  final RouteRepository _routes;
  late final StreamSubscription<List<Route>> _subscription;

  late final Command1<void, Route> delete;

  List<Route>? _all;

  /// Null until the routes were read the first time.
  List<Route>? get routes => _all;

  Future<Result<void>> _delete(Route route) => _routes.delete(route.id!);

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    delete.dispose();
    super.dispose();
  }
}

/// Renames a recorded route.
class RouteEditViewModel extends ChangeNotifier {
  RouteEditViewModel({required RouteRepository routeRepository, required this.route})
      : _routes = routeRepository {
    rename = Command1(_rename);
  }

  final RouteRepository _routes;
  final Route route;

  /// Fails if another route already has the name.
  late final Command1<int, String> rename;

  Future<Result<int>> _rename(String name) => _routes.save(route.copyWith(name: name.trim()));

  @override
  void dispose() {
    rename.dispose();
    super.dispose();
  }
}
