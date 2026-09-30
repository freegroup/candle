import 'package:candle/data/repositories/auth/auth_repository.dart';
import 'package:candle/data/services/attestation/attestation_service.dart';
import 'package:candle/data/services/candle_api/candle_api_client.dart';
import 'package:candle/data/services/candle_api/candle_api_exceptions.dart';
import 'package:candle/data/services/candle_api/server_config_service.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_attestation_service.dart';
import '../../fakes/fake_candle_server.dart';
import '../../fakes/in_memory_auth_storage.dart';

void main() {
  late FakeCandleServer server;
  late FakeAttestationService attestation;
  late InMemoryAuthStorage storage;
  late DateTime now;

  CandleApiClient api() => CandleApiClient(
        client: server.client,
        config: ServerConfigService(client: server.client, configUrl: Uri.parse(FakeCandleServer.configUrl)),
      );

  // A new repository is what the app has after a restart: only the storage survives.
  AuthRepository restartApp() =>
      AuthRepository(api: api(), attestation: attestation, storage: storage, now: () => now);

  Future<Result<Map<String, Object?>>> callMe(AuthRepository auth) =>
      auth.authorized((token) => api().get('/v1/me', accessToken: token));

  setUp(() {
    server = FakeCandleServer();
    attestation = FakeAttestationService();
    storage = InMemoryAuthStorage();
    now = DateTime(2026, 9, 30, 12);
  });

  test('registers on first use and keeps the iOS key id', () async {
    final auth = restartApp();
    expect(await auth.accessToken(), isA<Ok<String>>());

    expect(server.registrations, 1);
    expect(await auth.installationId(), 'installation-1');
    expect(storage.values['candle.keyId'], 'key-1');
  });

  test('concurrent callers share one registration', () async {
    final auth = restartApp();
    await Future.wait([auth.accessToken(), auth.accessToken(), auth.accessToken()]);
    expect(server.registrations, 1);
  });

  test('reuses the access token until shortly before it expires', () async {
    final auth = restartApp();
    await auth.accessToken();
    now = now.add(const Duration(minutes: 58));
    await auth.accessToken();
    expect(server.refreshes, 0);

    now = now.add(const Duration(minutes: 1, seconds: 1));
    await auth.accessToken();
    expect(server.refreshes, 1);
  });

  test('after an app restart it refreshes with an assertion of the same key', () async {
    await restartApp().accessToken();
    final auth = restartApp();
    expect(await auth.accessToken(), isA<Ok<String>>());

    expect(server.registrations, 1);
    expect(server.refreshes, 1);
    expect(attestation.assertionKeyIds, ['key-1']);
    expect(await auth.installationId(), 'installation-1');
  });

  test('registers again with a new key when the server was rebuilt', () async {
    await restartApp().accessToken();
    server.rebuild();

    final auth = restartApp();
    expect(await auth.accessToken(), isA<Ok<String>>());
    expect(server.registrations, 2);
    expect(storage.values['candle.keyId'], 'key-2');
    expect(await auth.installationId(), 'installation-2');
  });

  test('registers again when the iOS key is lost', () async {
    await restartApp().accessToken();
    attestation.assertionError = const InvalidKeyException();

    expect(await restartApp().accessToken(), isA<Ok<String>>());
    expect(server.registrations, 2);
  });

  test('retries a call once with a new token after 401', () async {
    final auth = restartApp();
    expect(await callMe(auth), isA<Ok<Map<String, Object?>>>());

    server.expireAccessTokens();
    expect(await callMe(auth), isA<Ok<Map<String, Object?>>>());
    expect(server.refreshes, 1);
  });

  group('offline', () {
    test('without the config file nothing is sent to any server', () async {
      server.configReachable = false;
      final result = await restartApp().accessToken();

      expect((result as Error<String>).error, isA<ServerUnavailableException>());
      expect(server.requests, isEmpty);
    });

    test('an unreachable server keeps the installation for later', () async {
      await restartApp().accessToken();
      server.serverReachable = false;

      final result = await restartApp().accessToken();
      expect((result as Error<String>).error, isA<ServerUnavailableException>());
      expect(storage.values['candle.refreshToken'], isNotNull);

      server.serverReachable = true;
      expect(await restartApp().accessToken(), isA<Ok<String>>());
      expect(server.registrations, 1);
    });

    test('a device that cannot attest stays offline', () async {
      attestation.attestError = const AttestationUnavailableException('simulator');
      final result = await restartApp().accessToken();
      expect((result as Error<String>).error, isA<AttestationUnavailableException>());
    });
  });
}
