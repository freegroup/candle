import 'package:permission_handler/permission_handler.dart';

/// The permissions Candle needs: location, and microphone plus speech
/// recognition for voice input.
class PermissionService {
  static const _required = [Permission.location, Permission.microphone, Permission.speech];

  Future<bool> allGranted() async {
    for (final permission in _required) {
      if (!await permission.isGranted) return false;
    }
    return true;
  }

  /// Asks the user for every missing permission; true if all are granted afterwards.
  Future<bool> requestAll() async {
    final statuses = await _required.request();
    return statuses.values.every((status) => status.isGranted);
  }

  /// Opens the system settings of the app, the only way back after a permanent denial.
  Future<void> openSettings() => openAppSettings();
}
