import 'package:candle/data/services/overpass/endpoint_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const a = 'https://a';
  const b = 'https://b';

  test('starts in the configured order, every endpoint unknown (8 s)', () {
    final ranking = EndpointRanking([a, b]);
    expect(ranking.ordered, [a, b]);
    expect(ranking.latencyOf(b), const Duration(seconds: 8));
  });

  test('a fast answer moves an endpoint to the front', () {
    final ranking = EndpointRanking([a, b])..recordSuccess(b, const Duration(seconds: 1));
    expect(ranking.ordered, [b, a]);
  });

  test('a failure counts as slow, even when the server refused quickly', () {
    final ranking = EndpointRanking([a, b])..recordFailure(a);
    expect(ranking.ordered, [b, a]);
    expect(ranking.latencyOf(a), greaterThan(const Duration(seconds: 8)));
  });

  test('one slow answer does not throw a good endpoint out at once, repeated ones do', () {
    final ranking = EndpointRanking([a, b])
      ..recordSuccess(a, const Duration(seconds: 1))
      ..recordSuccess(a, const Duration(seconds: 1))
      ..recordSuccess(a, const Duration(seconds: 1))
      ..recordSuccess(b, const Duration(seconds: 3))
      ..recordSuccess(b, const Duration(seconds: 3))
      ..recordSuccess(b, const Duration(seconds: 3));
    // a ≈ 3.4 s, b ≈ 4.7 s
    expect(ranking.ordered, [a, b]);

    ranking.recordSuccess(a, const Duration(seconds: 6));
    expect(ranking.ordered, [a, b], reason: 'a single outlier');

    ranking
      ..recordSuccess(a, const Duration(seconds: 6))
      ..recordSuccess(a, const Duration(seconds: 6));
    expect(ranking.ordered, [b, a]);
  });

  test('unknown endpoints are ignored', () {
    final ranking = EndpointRanking([a])..recordFailure('https://other');
    expect(ranking.ordered, [a]);
  });
}
