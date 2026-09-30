import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Proof that the request comes from the genuine app on a real device,
/// bound to a server challenge. [fields] go into the request body as they are.
final class DeviceProof {
  const DeviceProof(this.platform, this.fields);

  /// "ios", "android" or "debug", as the server expects it.
  final String platform;
  final Map<String, String> fields;
}

/// The iOS key is gone (e.g. app restored on a new phone): register again.
class InvalidKeyException implements Exception {
  const InvalidKeyException();
}

/// The device cannot attest (simulator, emulator, missing configuration).
class AttestationUnavailableException implements Exception {
  const AttestationUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'AttestationUnavailableException: $message';
}

/// Creates device proofs for the Candle server.
abstract interface class AttestationService {
  /// Proof for a new installation. On iOS this creates a new App Attest key,
  /// returned in `fields['keyId']`.
  Future<Result<DeviceProof>> attest(String challenge);

  /// Proof for a token refresh; [keyId] is the iOS key of the registration.
  Future<Result<DeviceProof>> assertion(String challenge, {String? keyId});
}

/// App Attest (iOS) and Play Integrity (Android) via the native channel
/// `candle/attestation` (AttestationChannel.swift / AttestationChannel.kt).
class PlatformAttestationService implements AttestationService {
  PlatformAttestationService({required this.playCloudProjectNumber, TargetPlatform? platform})
      : _platform = platform ?? defaultTargetPlatform;

  static const _channel = MethodChannel('candle/attestation');

  final int playCloudProjectNumber;
  final TargetPlatform _platform;

  @override
  Future<Result<DeviceProof>> attest(String challenge) => switch (_platform) {
        TargetPlatform.iOS => _invoke('attestKey', {'challenge': challenge}, 'ios'),
        TargetPlatform.android => _integrityToken(challenge),
        _ => Future.value(Result.error(AttestationUnavailableException('$_platform'))),
      };

  @override
  Future<Result<DeviceProof>> assertion(String challenge, {String? keyId}) => switch (_platform) {
        TargetPlatform.iOS when keyId != null =>
          _invoke('generateAssertion', {'challenge': challenge, 'keyId': keyId}, 'ios'),
        TargetPlatform.iOS => Future.value(const Result.error(InvalidKeyException())),
        TargetPlatform.android => _integrityToken(challenge),
        _ => Future.value(Result.error(AttestationUnavailableException('$_platform'))),
      };

  Future<Result<DeviceProof>> _integrityToken(String challenge) {
    if (playCloudProjectNumber == 0) {
      return Future.value(
          const Result.error(AttestationUnavailableException('PLAY_CLOUD_PROJECT_NUMBER not set')));
    }
    return _invoke(
      'integrityToken',
      {'challenge': challenge, 'cloudProjectNumber': playCloudProjectNumber},
      'android',
    );
  }

  Future<Result<DeviceProof>> _invoke(
    String method,
    Map<String, Object> arguments,
    String platform,
  ) async {
    try {
      final result = await _channel.invokeMapMethod<String, String>(method, arguments);
      return Result.ok(DeviceProof(platform, result ?? const {}));
    } on PlatformException catch (e) {
      if (e.code == 'invalid_key') return const Result.error(InvalidKeyException());
      return Result.error(AttestationUnavailableException('${e.code}: ${e.message}'));
    } on MissingPluginException {
      return const Result.error(AttestationUnavailableException('no native attestation channel'));
    }
  }
}

/// For simulators/emulators against a server with DEBUG_ATTESTATION_TOKEN.
class DebugAttestationService implements AttestationService {
  const DebugAttestationService(this.token);

  final String token;

  @override
  Future<Result<DeviceProof>> attest(String challenge) async =>
      Result.ok(DeviceProof('debug', {'debugToken': token}));

  @override
  Future<Result<DeviceProof>> assertion(String challenge, {String? keyId}) => attest(challenge);
}
