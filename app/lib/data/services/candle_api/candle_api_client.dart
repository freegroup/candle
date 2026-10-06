import 'dart:async';
import 'dart:convert';

import 'package:candle/data/services/attestation/attestation_service.dart';
import 'package:candle/data/services/candle_api/candle_api_exceptions.dart';
import 'package:candle/data/services/candle_api/server_config_service.dart';
import 'package:candle/config/app_config.dart';
import 'package:candle/utils/result.dart';
import 'package:http/http.dart' as http;

/// Tokens of an installation, see server/README.md.
final class AuthTokens {
  const AuthTokens({
    required this.installationId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String installationId;
  final String accessToken;
  final String refreshToken;
  final Duration expiresIn;

  static AuthTokens fromJson(Map<String, Object?> json) => AuthTokens(
        installationId: json['installationId']! as String,
        accessToken: json['accessToken']! as String,
        refreshToken: json['refreshToken']! as String,
        expiresIn: Duration(seconds: (json['expiresIn']! as num).toInt()),
      );
}

/// HTTP client for the Candle server.
class CandleApiClient {
  CandleApiClient({
    required this._client,
    required this._config,
    this.timeout = const Duration(seconds: 15),
  });

  final http.Client _client;
  final ServerConfigService _config;
  final Duration timeout;

  Future<Result<String>> challenge() async {
    final result = await _send('POST', '/v1/auth/challenge');
    return switch (result) {
      Ok(:final value) => Result.ok(value['challenge']! as String),
      Error(:final error) => Result.error(error),
    };
  }

  Future<Result<AuthTokens>> register(String challenge, DeviceProof proof) => _tokens(
        '/v1/auth/register',
        {'platform': proof.platform, 'challenge': challenge, ...proof.fields},
      );

  Future<Result<AuthTokens>> refresh(String refreshToken, String challenge, DeviceProof proof) =>
      _tokens(
        '/v1/auth/refresh',
        {'refreshToken': refreshToken, 'challenge': challenge, ...proof.fields},
      );

  /// GET of a protected endpoint.
  Future<Result<Map<String, Object?>>> get(String path, {required String accessToken}) =>
      _send('GET', path, accessToken: accessToken);

  /// POST of [body] as JSON to a protected endpoint.
  Future<Result<Map<String, Object?>>> post(
    String path,
    Map<String, String> body, {
    required String accessToken,
  }) =>
      _send('POST', path, body: body, accessToken: accessToken);

  Future<Result<AuthTokens>> _tokens(String path, Map<String, String> body) async {
    final result = await _send('POST', path, body: body);
    switch (result) {
      case Ok(:final value):
        try {
          return Result.ok(AuthTokens.fromJson(value));
        } on Object catch (e) {
          return Result.error(CandleApiException(200, 'unexpected token answer: $e'));
        }
      case Error(:final error):
        return Result.error(error);
    }
  }

  Future<Result<Map<String, Object?>>> _send(
    String method,
    String path, {
    Map<String, String>? body,
    String? accessToken,
  }) async {
    final base = await _config.apiUrl();
    if (base is Error<Uri>) return Result.error(base.error);

    final request = http.Request(method, (base as Ok<Uri>).value.resolve(path))
      ..headers.addAll({
        ...HttpConfig.headers,
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      });
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }

    try {
      final response = await http.Response.fromStream(await _client.send(request).timeout(timeout));
      final json = response.body.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
      final map = json is Map<String, Object?> ? json : const <String, Object?>{};
      final message = '${map['message'] ?? response.reasonPhrase ?? ''}';

      if (response.statusCode == 401) return Result.error(UnauthorizedException(message));
      if (response.statusCode >= 300) return Result.error(CandleApiException(response.statusCode, message));
      return Result.ok(map);
    } on TimeoutException {
      return Result.error(const ServerUnavailableException('timeout'));
    } on http.ClientException catch (e) {
      return Result.error(ServerUnavailableException(e.message));
    } on FormatException catch (e) {
      return Result.error(CandleApiException(0, 'invalid answer: ${e.message}'));
    }
  }
}
