import 'dart:convert';

import 'package:candle/data/services/overpass/overpass_client.dart';
import 'package:candle/data/services/overpass/overpass_element.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _body = {
  'elements': [
    {'type': 'node', 'id': 1, 'lat': 52.5, 'lon': 13.4, 'tags': {'name': 'Café A'}},
    {'type': 'way', 'id': 2, 'center': {'lat': 52.6, 'lon': 13.5}, 'tags': {'highway': 'crossing'}},
    {'type': 'relation', 'id': 3, 'tags': {'name': 'no position'}},
  ],
};

http.Response _ok() => http.Response.bytes(utf8.encode(jsonEncode(_body)), 200);

void main() {
  test('parses nodes and ways (via center), skips elements without position', () async {
    final client = OverpassClient(client: MockClient((_) async => _ok()), endpoints: ['https://a']);
    final result = await client.query('q');

    final elements = (result as Ok<List<OverpassElement>>).value;
    expect(elements.map((e) => e.id), [1, 2]);
    expect(elements[1].lat, 52.6);
    expect(elements[0].tags['name'], 'Café A');
  });

  test('sends a User-Agent and the query as form data', () async {
    late http.Request sent;
    final client = OverpassClient(
      client: MockClient((request) async {
        sent = request;
        return _ok();
      }),
      endpoints: ['https://a'],
    );
    await client.query('[out:json];node(1);out;');

    expect(sent.method, 'POST');
    expect(sent.headers['User-Agent'], startsWith('Candle/'));
    expect(sent.bodyFields['data'], '[out:json];node(1);out;');
  });

  test('falls back to the next endpoint on 429 and 5xx', () async {
    final hosts = <String>[];
    final client = OverpassClient(
      client: MockClient((request) async {
        hosts.add(request.url.host);
        return switch (request.url.host) {
          'a' => http.Response('busy', 429),
          'b' => http.Response('down', 504),
          _ => _ok(),
        };
      }),
      endpoints: ['https://a', 'https://b', 'https://c'],
    );

    expect(await client.query('q'), isA<Ok<List<OverpassElement>>>());
    expect(hosts, ['a', 'b', 'c']);
  });

  test('does not retry client errors such as 406', () async {
    var calls = 0;
    final client = OverpassClient(
      client: MockClient((_) async {
        calls++;
        return http.Response('no', 406);
      }),
      endpoints: ['https://a', 'https://b'],
    );

    final result = await client.query('q');
    expect(result, isA<Error<List<OverpassElement>>>());
    expect(calls, 1);
  });

  test('returns an error when all endpoints fail', () async {
    final client = OverpassClient(
      client: MockClient((_) async => throw http.ClientException('offline')),
      endpoints: ['https://a', 'https://b'],
      retryPause: Duration.zero,
    );
    expect(await client.query('q'), isA<Error<List<OverpassElement>>>());
  });

  test('tries again when every endpoint failed, and succeeds when a server is free again',
      () async {
    var calls = 0;
    final client = OverpassClient(
      client: MockClient((_) async {
        calls++;
        return calls <= 2 ? http.Response('busy', 504) : _ok();
      }),
      endpoints: ['https://a', 'https://b'],
      retryPause: Duration.zero,
    );

    expect(await client.query('q'), isA<Ok<List<OverpassElement>>>());
    expect(calls, 3, reason: 'both endpoints in the first attempt, then one in the second');
  });

  test('gives up after the configured attempts', () async {
    var calls = 0;
    final client = OverpassClient(
      client: MockClient((_) async {
        calls++;
        return http.Response('busy', 504);
      }),
      endpoints: ['https://a', 'https://b'],
      attempts: 3,
      retryPause: Duration.zero,
    );

    expect(await client.query('q'), isA<Error<List<OverpassElement>>>());
    expect(calls, 6, reason: '3 attempts with 2 endpoints each');
  });

  test('stops at the total time limit, even before all attempts ran', () async {
    var calls = 0;
    final client = OverpassClient(
      client: MockClient((_) async {
        calls++;
        await Future<void>.delayed(const Duration(seconds: 1)); // hanging server
        return _ok();
      }),
      endpoints: ['https://a', 'https://b'],
      timeout: const Duration(milliseconds: 100),
      attempts: 3,
      retryPause: Duration.zero,
      totalTimeout: const Duration(milliseconds: 250),
    );

    final stopwatch = Stopwatch()..start();
    expect(await client.query('q'), isA<Error<List<OverpassElement>>>());
    expect(calls, lessThan(6));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
  });

  test('after a failure the next query goes to the other endpoint first', () async {
    final asked = <String>[];
    final client = OverpassClient(
      client: MockClient((request) async {
        asked.add(request.url.host);
        return request.url.host == 'a' ? http.Response('', 504) : _ok();
      }),
      endpoints: ['https://a', 'https://b'],
    );

    await client.query('q1');
    expect(asked, ['a', 'b']);

    asked.clear();
    await client.query('q2');
    expect(asked, ['b'], reason: 'the failing endpoint is no longer asked first');
  });

  test('gives up on a hanging endpoint after the timeout and asks the next', () async {
    final client = OverpassClient(
      client: MockClient((request) async {
        if (request.url.host == 'a') await Future<void>.delayed(const Duration(seconds: 1));
        return _ok();
      }),
      endpoints: ['https://a', 'https://b'],
      timeout: const Duration(milliseconds: 50),
    );

    expect(await client.query('q'), isA<Ok<List<OverpassElement>>>());
  });
}
