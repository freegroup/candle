import 'package:candle/data/services/candle_api/candle_api_exceptions.dart';
import 'package:candle/data/services/candle_api/server_config_service.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final configUrl = Uri.parse('https://config.test/api.json');
  var calls = 0;

  ServerConfigService service(String body, {int status = 200}) => ServerConfigService(
        client: MockClient((_) async {
          calls++;
          return http.Response(body, status);
        }),
        configUrl: configUrl,
      );

  setUp(() => calls = 0);

  test('reads the server address once', () async {
    final config = service('{"apiUrl": "https://2-28-137-196.sslip.io"}');
    expect((await config.apiUrl() as Ok<Uri>).value, Uri.parse('https://2-28-137-196.sslip.io'));
    await config.apiUrl();
    expect(calls, 1);
  });

  for (final (name, body, status) in [
    ('http instead of https', '{"apiUrl": "http://2.28.137.196"}', 200),
    ('a missing apiUrl', '{}', 200),
    ('no JSON', '<html>', 200),
    ('a missing file', '', 404),
  ]) {
    test('treats $name as offline', () async {
      final result = await service(body, status: status).apiUrl();
      expect((result as Error<Uri>).error, isA<ServerUnavailableException>());
    });
  }

  test('tries again after a failure', () async {
    final config = ServerConfigService(
      client: MockClient((_) async => ++calls == 1
          ? throw http.ClientException('offline')
          : http.Response('{"apiUrl": "https://api.test"}', 200)),
      configUrl: configUrl,
    );
    expect(await config.apiUrl(), isA<Error<Uri>>());
    expect(await config.apiUrl(), isA<Ok<Uri>>());
  });

  test('the development override skips the lookup', () async {
    final config = ServerConfigService(
      client: MockClient((_) async => throw StateError('must not be called')),
      configUrl: configUrl,
      apiUrlOverride: Uri.parse('http://10.0.2.2:8080'),
    );
    expect((await config.apiUrl() as Ok<Uri>).value.port, 8080);
  });
}
