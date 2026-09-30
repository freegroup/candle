import 'dart:async';
import 'dart:convert';

import 'package:candle/data/services/overpass/overpass_element.dart';
import 'package:candle/utils/configuration.dart';
import 'package:candle/utils/result.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final _log = Logger();

/// Thin client for the Overpass API.
///
/// The public instances are frequently overloaded (429/5xx) or slow, so the
/// query is retried on the next endpoint in [endpoints].
class OverpassClient {
  OverpassClient({
    required this._client,
    this.endpoints = defaultEndpoints,
    this.timeout = const Duration(seconds: 25),
  });

  // Other public instances were tested as fallback (09/2026): private.coffee and
  // kumi.systems did not answer, maps.mail.ru is operated in Russia and must not
  // receive the positions of our users. The own Candle server goes here later.
  static const defaultEndpoints = ['https://overpass-api.de/api/interpreter'];

  final http.Client _client;
  final List<String> endpoints;
  final Duration timeout;

  /// Runs an Overpass QL query that returns JSON (`[out:json]`).
  Future<Result<List<OverpassElement>>> query(String overpassQl) async {
    Exception lastError = Exception('No Overpass endpoint configured');

    for (final endpoint in endpoints) {
      try {
        final response = await _client
            .post(Uri.parse(endpoint), headers: kHttpHeaders, body: {'data': overpassQl})
            .timeout(timeout);

        if (response.statusCode == 200) {
          return Result.ok(_parse(response.bodyBytes));
        }
        lastError = OverpassException(endpoint, response.statusCode);
        // Only overload/server errors are worth retrying on another instance.
        if (response.statusCode != 429 && response.statusCode < 500) break;
      } on TimeoutException {
        lastError = OverpassException(endpoint, null, 'timeout');
      } on http.ClientException catch (e) {
        lastError = OverpassException(endpoint, null, e.message);
      } on FormatException catch (e) {
        return Result.error(e);
      }
      _log.w('Overpass request failed: $lastError');
    }
    return Result.error(lastError);
  }

  List<OverpassElement> _parse(List<int> bodyBytes) {
    final json = jsonDecode(utf8.decode(bodyBytes));
    if (json is! Map<String, Object?>) throw const FormatException('Unexpected Overpass response');
    final elements = json['elements'];
    if (elements is! List<Object?>) return const [];
    return elements
        .whereType<Map<String, Object?>>()
        .map(OverpassElement.fromJson)
        .nonNulls
        .toList();
  }
}

class OverpassException implements Exception {
  const OverpassException(this.endpoint, this.statusCode, [this.message]);

  final String endpoint;
  final int? statusCode;
  final String? message;

  @override
  String toString() => 'OverpassException($endpoint, status: $statusCode, ${message ?? ''})';
}
