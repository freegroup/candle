import 'dart:async';

import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/permissions/permission_service.dart';
import 'package:candle/utils/command.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Drives the start of the app: the welcome screen on first run / after an
/// update, then the permission gate, then the tabs.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required PermissionService permissionService,
    required SettingsRepository settingsRepository,
  })  : _permissions = permissionService,
        _settings = settingsRepository {
    request = Command0(_request);
    unawaited(_init());
  }

  final PermissionService _permissions;
  final SettingsRepository _settings;

  /// Asks for the permissions; fails if the user denies one.
  late final Command0<void> request;

  String _version = '';

  bool? _welcomeDone;

  /// Null while checking, then whether the welcome screen for the current app
  /// version has already been seen.
  bool? get welcomeDone => _welcomeDone;

  bool? _granted;

  /// Null while checking, then whether all permissions are granted.
  bool? get granted => _granted;

  Future<void> _init() async {
    final info = await PackageInfo.fromPlatform();
    _version = info.version;
    _welcomeDone = _settings.welcomeSeenVersion == _version;
    notifyListeners();
    _granted = await _permissions.allGranted();
    notifyListeners();
  }

  /// Remembers that the welcome screen for this version was seen, so it is not
  /// shown again until the next update.
  Future<void> completeWelcome() async {
    await _settings.setWelcomeSeen(_version);
    _welcomeDone = true;
    notifyListeners();
  }

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
