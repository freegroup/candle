import 'package:candle/data/repositories/settings/settings_repository.dart';
import 'package:candle/data/services/permissions/permission_service.dart';
import 'package:candle/ui/onboarding/view_models/onboarding_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakePermissions implements PermissionService {
  _FakePermissions(this.granted);
  final bool granted;
  @override
  Future<bool> allGranted() async => granted;
  @override
  Future<bool> requestAll() async => granted;
  @override
  Future<void> requestNotifications() async {}
  @override
  Future<void> openSettings() async {}
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsRepository settings;
  setUp(() async {
    PackageInfo.setMockInitialValues(
        appName: 'Candle', packageName: 'x', version: '1.5.0', buildNumber: '1', buildSignature: '');
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = SettingsRepository(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions()));
  });

  test('shows the welcome screen when no version was seen yet', () async {
    final vm = OnboardingViewModel(
        permissionService: _FakePermissions(true), settingsRepository: settings);
    await _settle();
    expect(vm.welcomeDone, false);
    expect(vm.granted, true);
  });

  test('skips the welcome screen when the current version was already seen', () async {
    await settings.setWelcomeSeen('1.5.0');
    final vm = OnboardingViewModel(
        permissionService: _FakePermissions(false), settingsRepository: settings);
    await _settle();
    expect(vm.welcomeDone, true);
    expect(vm.granted, false);
  });

  test('completing the welcome stores the current version', () async {
    final vm = OnboardingViewModel(
        permissionService: _FakePermissions(true), settingsRepository: settings);
    await _settle();
    await vm.completeWelcome();
    expect(vm.welcomeDone, true);
    expect(settings.welcomeSeenVersion, '1.5.0');
  });
}
