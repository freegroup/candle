import 'package:collection/collection.dart';

/// Orders a fixed set of server endpoints by how fast they answered recently,
/// so the fastest one is asked first and a slow or failing one moves back.
///
/// Every endpoint starts with [initialLatency] ("unknown"). Each answer moves its
/// latency towards the measured time (moving average with [weight]); a failure
/// counts as [failureLatency], so a server that refuses quickly (e.g. 429 after
/// 0.1 s) does not look fast.
class EndpointRanking {
  EndpointRanking(
    List<String> endpoints, {
    this.initialLatency = const Duration(seconds: 8),
    this.failureLatency = const Duration(seconds: 30),
    this.weight = 0.3,
  }) : _latencies = {for (final endpoint in endpoints) endpoint: initialLatency},
       _order = List.of(endpoints);

  final Duration initialLatency;
  final Duration failureLatency;

  /// Share of a new measurement in the moving average (0..1).
  final double weight;

  final Map<String, Duration> _latencies;

  /// Ties keep the order of the configured list.
  final List<String> _order;

  /// The endpoints, fastest first.
  List<String> get ordered {
    final sorted = List.of(_order);
    mergeSort<String>(sorted, compare: (a, b) => _latencies[a]!.compareTo(_latencies[b]!));
    return sorted;
  }

  Duration latencyOf(String endpoint) => _latencies[endpoint]!;

  void recordSuccess(String endpoint, Duration latency) => _record(endpoint, latency);

  void recordFailure(String endpoint) => _record(endpoint, failureLatency);

  void _record(String endpoint, Duration measured) {
    final current = _latencies[endpoint];
    if (current == null) return;
    _latencies[endpoint] = current * (1 - weight) + measured * weight;
  }
}
