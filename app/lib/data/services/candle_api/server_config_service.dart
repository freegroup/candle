import 'dart:async';
import 'dart:convert';

import 'package:candle/data/services/candle_api/candle_api_exceptions.dart';
import 'package:candle/utils/configuration.dart';
import 'package:candle/utils/result.dart';
import 'package:http/http.dart' as http;

/// Finds the Candle server: `{"apiUrl": "https://…"}` in a file on GitHub Pages,
/// so a new server only needs an updated file instead of an app release.
///
/// Without the file (or the network) the app works offline; there is no
/// built-in fallback address on purpose.
class ServerConfigService {
  ServerConfigService({
    required this._client,
    required this.configUrl,
    this.apiUrlOverride,
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client _client;
  final Uri configUrl;

  /// Development only: use this server instead of looking it up (may be http).
  final Uri? apiUrlOverride;
  final Duration timeout;

  Uri? _apiUrl;

  /// The server address; looked up once per app start, again after a failure.
  Future<Result<Uri>> apiUrl() async {
    final known = apiUrlOverride ?? _apiUrl;
    if (known != null) return Result.ok(known);

    try {
      final response = await _client.get(configUrl, headers: kHttpHeaders).timeout(timeout);
      if (response.statusCode != 200) {
        return Result.error(ServerUnavailableException('server config: HTTP ${response.statusCode}'));
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final url = json is Map<String, Object?> ? Uri.tryParse('${json['apiUrl']}') : null;
      if (url == null || url.scheme != 'https' || url.host.isEmpty) {
        return Result.error(ServerUnavailableException('server config: invalid apiUrl'));
      }
      return Result.ok(_apiUrl = url);
    } on FormatException catch (e) {
      return Result.error(ServerUnavailableException('server config: $e'));
    } on TimeoutException {
      return Result.error(ServerUnavailableException('server config: timeout'));
    } on http.ClientException catch (e) {
      return Result.error(ServerUnavailableException('server config: ${e.message}'));
    }
  }
}
