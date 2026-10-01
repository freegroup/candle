import 'dart:async';

import 'package:candle/data/services/permissions/permission_service.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';

/// Checks at start whether Candle has the permissions it needs, and asks for them.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({required PermissionService permissionService})
      : _permissions = permissionService {
    request = Command0(_request);
    unawaited(_permissions.allGranted().then((granted) {
      _granted = granted;
      notifyListeners();
    }));
  }

  final PermissionService _permissions;

  /// Asks for the permissions; fails if the user denies one.
  late final Command0<void> request;

  bool? _granted;

  /// Null while checking, then whether all permissions are granted.
  bool? get granted => _granted;

  Future<void> openSettings() => _permissions.openSettings();

  Future<Result<void>> _request() async {
    _granted = await _permissions.requestAll();
    notifyListeners();
    return _granted! ? const Result.ok(null) : Result.error(Exception('Permission denied'));
  }

  @override
  void dispose() {
    request.dispose();
    super.dispose();
  }
}
