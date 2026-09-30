import 'dart:async';

import 'package:candle/data/repositories/auth/auth_storage.dart';
import 'package:candle/data/services/attestation/attestation_service.dart';
import 'package:candle/data/services/candle_api/candle_api_client.dart';
import 'package:candle/data/services/candle_api/candle_api_exceptions.dart';
import 'package:candle/utils/result.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Anonymous identity of this installation at the Candle server.
///
/// Registers on first use, refreshes the short-lived access token with a fresh
/// device proof, and registers again whenever the server no longer knows the
/// installation (expired, server rebuilt, iOS key lost). Errors are returned,
/// never thrown: without server the app works offline.
class AuthRepository {
  AuthRepository({
    required this._api,
    required this._attestation,
    required this._storage,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const _refreshTokenKey = 'candle.refreshToken';
  static const _keyIdKey = 'candle.keyId';
  static const _installationIdKey = 'candle.installationId';

  final CandleApiClient _api;
  final AttestationService _attestation;
  final AuthStorage _storage;
  final DateTime Function() _now;

  String? _accessToken;
  DateTime? _validUntil;
  Future<Result<String>>? _pending;

  /// Id of this installation once registered.
  Future<String?> installationId() => _storage.read(_installationIdKey);

  /// A valid access token; registers or refreshes when needed.
  Future<Result<String>> accessToken() {
    final token = _accessToken;
    if (token != null && _now().isBefore(_validUntil!)) return Future.value(Result.ok(token));
    // One registration/refresh at a time, shared by all callers.
    return _pending ??= _obtainToken().whenComplete(() => _pending = null);
  }

  /// Calls a protected endpoint; on 401 once more with a new token.
  Future<Result<T>> authorized<T>(Future<Result<T>> Function(String accessToken) call) async {
    for (var attempt = 0; ; attempt++) {
      final token = await accessToken();
      if (token is Error<String>) return Result.error(token.error);
      final result = await call((token as Ok<String>).value);
      if (attempt > 0 || result is! Error<T> || result.error is! UnauthorizedException) return result;
      _accessToken = null;
    }
  }

  Future<Result<String>> _obtainToken() async {
    final refreshToken = await _storage.read(_refreshTokenKey);
    if (refreshToken != null) {
      final refreshed = await _refresh(refreshToken);
      if (refreshed is Ok<String>) return refreshed;
      final error = (refreshed as Error<String>).error;
      if (error is! UnauthorizedException && error is! InvalidKeyException) return refreshed;
      _log.i('Installation no longer valid ($error), registering again');
      await _forget();
    }
    return _register();
  }

  Future<Result<String>> _register() async {
    final challenge = await _api.challenge();
    if (challenge is Error<String>) return Result.error(challenge.error);
    final value = (challenge as Ok<String>).value;

    final proof = await _attestation.attest(value);
    if (proof is Error<DeviceProof>) return Result.error(proof.error);
    final deviceProof = (proof as Ok<DeviceProof>).value;

    final tokens = await _api.register(value, deviceProof);
    if (tokens is Ok<AuthTokens>) {
      final keyId = deviceProof.fields['keyId'];
      if (keyId != null) await _storage.write(_keyIdKey, keyId);
      _log.i('Registered installation ${tokens.value.installationId}');
    }
    return _accept(tokens);
  }

  Future<Result<String>> _refresh(String refreshToken) async {
    final challenge = await _api.challenge();
    if (challenge is Error<String>) return Result.error(challenge.error);
    final value = (challenge as Ok<String>).value;

    final proof = await _attestation.assertion(value, keyId: await _storage.read(_keyIdKey));
    if (proof is Error<DeviceProof>) return Result.error(proof.error);

    return _accept(await _api.refresh(refreshToken, value, (proof as Ok<DeviceProof>).value));
  }

  Future<Result<String>> _accept(Result<AuthTokens> result) async {
    switch (result) {
      case Ok(:final value):
        await _storage.write(_refreshTokenKey, value.refreshToken);
        await _storage.write(_installationIdKey, value.installationId);
        _accessToken = value.accessToken;
        // renew a minute early, so a request never starts with an expiring token
        _validUntil = _now().add(value.expiresIn - const Duration(minutes: 1));
        return Result.ok(value.accessToken);
      case Error(:final error):
        return Result.error(error);
    }
  }

  Future<void> _forget() async {
    _accessToken = null;
    await _storage.delete(_refreshTokenKey);
    await _storage.delete(_keyIdKey);
    await _storage.delete(_installationIdKey);
  }
}
