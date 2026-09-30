import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// In-memory stand-in for the Candle server and the GitHub Pages config file.
class FakeCandleServer {
  static const configUrl = 'https://config.test/api.json';
  static const apiUrl = 'https://api.test';

  bool configReachable = true;
  bool serverReachable = true;

  /// Tokens issued since the last [rebuild]; a rebuild forgets all of them.
  final _refreshTokens = <String, String>{}; // token -> installationId
  final _accessTokens = <String>{};
  final _challenges = <String>{};
  int _counter = 0;

  int registrations = 0;
  int refreshes = 0;
  final List<Map<String, Object?>> requests = [];

  /// Simulates a new server with a new JWT secret: all tokens become invalid.
  void rebuild() {
    _refreshTokens.clear();
    _accessTokens.clear();
  }

  /// Makes all access tokens invalid, e.g. expired.
  void expireAccessTokens() => _accessTokens.clear();

  late final http.Client client = MockClient((request) async {
    final url = request.url.toString();
    if (url == configUrl) {
      if (!configReachable) throw http.ClientException('no network');
      return _json({'apiUrl': apiUrl});
    }
    if (!serverReachable) throw http.ClientException('connection refused');

    final body = request.body.isEmpty ? <String, Object?>{} : jsonDecode(request.body) as Map<String, Object?>;
    requests.add({'path': request.url.path, ...body});

    switch (request.url.path) {
      case '/v1/auth/challenge':
        final challenge = 'c${_counter++}';
        _challenges.add(challenge);
        return _json({'challenge': challenge});
      case '/v1/auth/register':
        if (!_challenges.remove(body['challenge'])) return _unauthorized();
        registrations++;
        return _issue('installation-$registrations', status: 201);
      case '/v1/auth/refresh':
        final installation = _refreshTokens.remove(body['refreshToken']);
        if (installation == null || !_challenges.remove(body['challenge'])) return _unauthorized();
        refreshes++;
        return _issue(installation);
      case '/v1/me':
        final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
        if (!_accessTokens.contains(token)) return _unauthorized();
        return _json({'installationId': 'me'});
    }
    return http.Response('', 404);
  });

  http.Response _issue(String installationId, {int status = 200}) {
    final access = 'access-${_counter++}';
    final refresh = 'refresh-${_counter++}';
    _accessTokens.add(access);
    _refreshTokens[refresh] = installationId;
    return _json({
      'installationId': installationId,
      'accessToken': access,
      'refreshToken': refresh,
      'expiresIn': 3600,
    }, status: status);
  }

  http.Response _unauthorized() => _json({'error': 'unauthorized', 'message': 'nope'}, status: 401);

  http.Response _json(Object body, {int status = 200}) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
}
