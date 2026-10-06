import 'dart:async';
import 'dart:convert';

import 'package:candle/data/services/overpass/endpoint_ranking.dart';
import 'package:candle/data/services/overpass/overpass_element.dart';
import 'package:candle/config/app_config.dart';
import 'package:candle/utils/result.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final _log = Logger();

/// Asks the own Candle server for an Overpass query and gives its JSON answer;
/// it knows the server address and the login token.
typedef CandleServerQuery = Future<Result<Map<String, Object?>>> Function(String overpassQl);

/// Thin client for the Overpass API.
///
/// The public instances are frequently overloaded (429/5xx) or slow. Each query
/// goes to the endpoint that answered fastest recently ([EndpointRanking]) and
/// falls back to the next one if it fails; callers never see which one answered.
/// When every endpoint failed, the query is tried again after a short pause, up
/// to [attempts] times and at most [totalTimeout] in all.
///
/// With a [candleServer], each query goes there first. It answers from its own
/// data within its area and refuses everything else (outside its area, another
/// kind of query, no login); then the public endpoints are asked as before.
class OverpassClient {
  OverpassClient({
    required this._client,
    this._candleServer,
    this.candleTimeout = OverpassConfig.candleTimeout,
    List<String> endpoints = OverpassConfig.endpoints,
    this.timeout = OverpassConfig.timeout,
    this.attempts = OverpassConfig.attempts,
    this.retryPause = OverpassConfig.retryPause,
    this.totalTimeout = OverpassConfig.totalTimeout,
  }) : _ranking = EndpointRanking(endpoints);

  final http.Client _client;
  final CandleServerQuery? _candleServer;
  final EndpointRanking _ranking;

  /// Longest wait for the Candle server before the public endpoints are asked.
  final Duration candleTimeout;

  /// Longest wait for one endpoint before the next one is asked.
  final Duration timeout;

  /// How often the query is tried in all, each time with every endpoint.
  final int attempts;

  /// Pause before the next attempt.
  final Duration retryPause;

  /// Longest wait for the query in all, attempts and pauses included.
  final Duration totalTimeout;

  /// Runs an Overpass QL query that returns JSON (`[out:json]`).
  Future<Result<List<OverpassElement>>> query(String overpassQl) async {
    final fromCandle = await _askCandleServer(overpassQl);
    if (fromCandle != null) return Result.ok(fromCandle);

    final elapsed = Stopwatch()..start();
    var result = await _askEndpoints(overpassQl, elapsed);
    for (var attempt = 2; attempt <= attempts; attempt++) {
      if (result is Ok || !_worthRetrying(result)) return result;
      if (elapsed.elapsed + retryPause >= totalTimeout) return result;
      _log.w('Overpass attempt ${attempt - 1} of $attempts failed, trying again');
      await Future<void>.delayed(retryPause);
      result = await _askEndpoints(overpassQl, elapsed);
    }
    return result;
  }

  /// The places from the Candle server, or null when it did not answer them.
  Future<List<OverpassElement>?> _askCandleServer(String overpassQl) async {
    final candleServer = _candleServer;
    if (candleServer == null) return null;
    try {
      final result = await candleServer(overpassQl).timeout(candleTimeout);
      if (result is Error<Map<String, Object?>>) {
        _log.d('Candle server did not answer, asking public Overpass servers: ${result.error}');
        return null;
      }
      final json = (result as Ok<Map<String, Object?>>).value;
      if (json['elements'] is! List<Object?>) return null;
      final elements = _elementsOf(json);
      _log.d('Candle server answered with ${elements.length} elements');
      return elements;
    } on TimeoutException {
      _log.d('Candle server too slow, asking public Overpass servers');
      return null;
    }
  }

  /// A broken query (4xx) or an unreadable answer stays broken; only busy or
  /// unreachable servers are worth another try.
  static bool _worthRetrying(Result<List<OverpassElement>> result) {
    if (result is! Error<List<OverpassElement>>) return false;
    final error = result.error;
    if (error is! OverpassException) return false;
    final status = error.statusCode;
    return status == null || status == 429 || status >= 500;
  }

  /// One attempt: every endpoint in turn until one answers.
  Future<Result<List<OverpassElement>>> _askEndpoints(String overpassQl, Stopwatch elapsed) async {
    Exception lastError = Exception('No Overpass endpoint configured');

    for (final endpoint in _ranking.ordered) {
      final left = totalTimeout - elapsed.elapsed;
      if (left <= Duration.zero) {
        lastError = OverpassException(endpoint, null, 'timeout');
        break;
      }
      final stopwatch = Stopwatch()..start();
      try {
        final response = await _client
            .post(Uri.parse(endpoint), headers: HttpConfig.headers, body: {'data': overpassQl})
            .timeout(left < timeout ? left : timeout);

        if (response.statusCode == 200) {
          _ranking.recordSuccess(endpoint, stopwatch.elapsed);
          return Result.ok(_parse(response.bodyBytes));
        }
        lastError = OverpassException(endpoint, response.statusCode);
        // Other client errors mean a broken query, not a broken server.
        if (response.statusCode != 429 && response.statusCode < 500) break;
      } on TimeoutException {
        lastError = OverpassException(endpoint, null, 'timeout');
      } on http.ClientException catch (e) {
        lastError = OverpassException(endpoint, null, e.message);
      } on FormatException catch (e) {
        return Result.error(e);
      }
      _ranking.recordFailure(endpoint);
      _log.w('Overpass request failed: $lastError');
    }
    return Result.error(lastError);
  }

  List<OverpassElement> _parse(List<int> bodyBytes) {
    final json = jsonDecode(utf8.decode(bodyBytes));
    if (json is! Map<String, Object?>) throw const FormatException('Unexpected Overpass response');
    return _elementsOf(json);
  }

  static List<OverpassElement> _elementsOf(Map<String, Object?> json) {
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
