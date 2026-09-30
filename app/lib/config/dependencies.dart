import 'dart:async';

import 'package:candle/config/environment.dart';
import 'package:candle/data/repositories/auth/auth_repository.dart';
import 'package:candle/data/repositories/auth/auth_storage.dart';
import 'package:candle/data/repositories/poi/poi_repository.dart';
import 'package:candle/data/repositories/poi/poi_repository_remote.dart';
import 'package:candle/data/services/attestation/attestation_service.dart';
import 'package:candle/data/services/candle_api/candle_api_client.dart';
import 'package:candle/data/services/candle_api/server_config_service.dart';
import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/data/services/overpass/overpass_client.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/router.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

final _log = Logger();

/// Services and repositories available to the whole app.
List<SingleChildWidget> get providers => [
      Provider<http.Client>(create: (_) => http.Client(), dispose: (_, client) => client.close()),
      Provider(create: (context) => OverpassClient(client: context.read())),
      Provider(create: (_) => LocationService()),
      Provider(create: (_) => CompassService()),
      Provider<PoiRepository>(create: (context) => PoiRepositoryRemote(overpass: context.read())),
      Provider(
        create: (context) => ServerConfigService(
          client: context.read(),
          configUrl: Uri.parse(Environment.configUrl),
          apiUrlOverride: Environment.apiUrlOverride.isEmpty ? null : Uri.parse(Environment.apiUrlOverride),
        ),
      ),
      Provider(create: (context) => CandleApiClient(client: context.read(), config: context.read())),
      Provider<AttestationService>(
        create: (_) => kDebugMode && Environment.debugAttestationToken.isNotEmpty
            ? const DebugAttestationService(Environment.debugAttestationToken)
            : PlatformAttestationService(playCloudProjectNumber: Environment.playCloudProjectNumber),
      ),
      // Not lazy: registers the installation right at app start, so the first
      // server feature does not wait for it. Failing means offline, not an error.
      Provider(
        lazy: false,
        create: (context) {
          final auth = AuthRepository(
            api: context.read(),
            attestation: context.read(),
            storage: SecureAuthStorage(),
          );
          unawaited(auth.accessToken().then((result) {
            if (result is Error<String>) _log.i('Candle server not available, offline: ${result.error}');
          }));
          return auth;
        },
      ),

      // Legacy services, removed while the screens are migrated.
      ChangeNotifierProvider(create: (_) => GeoServiceProvider()),
      ChangeNotifierProvider(create: (_) => RoutingProvider()),
    ];
