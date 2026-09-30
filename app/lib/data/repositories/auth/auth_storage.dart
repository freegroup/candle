import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Where the installation keeps its refresh token and iOS key id.
abstract interface class AuthStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Keychain (iOS) / encrypted storage (Android).
class SecureAuthStorage implements AuthStorage {
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on Exception catch (e) {
      // e.g. an Android backup restored on another phone cannot be decrypted;
      // the installation then simply registers again.
      _log.w('Secure storage unreadable, starting over: $e');
      await _storage.deleteAll();
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
