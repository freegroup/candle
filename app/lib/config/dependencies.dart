import 'dart:async';

import 'package:candle/config/environment.dart';
import 'package:candle/data/repositories/auth/auth_repository.dart';
import 'package:candle/data/repositories/auth/auth_storage.dart';
import 'package:candle/data/repositories/poi/poi_repository.dart';
import 'package:candle/data/repositories/geocoding/geocoding_repository.dart';
import 'package:candle/data/repositories/locations/location_repository.dart';
import 'package:candle/data/repositories/poi/poi_repository_remote.dart';
import 'package:candle/data/repositories/recording/recording_repository.dart';
import 'package:candle/data/repositories/routes/route_repository.dart';
import 'package:candle/data/repositories/routing/routing_repository.dart';
import 'package:candle/data/repositories/location_notes/location_note_announcer.dart';
import 'package:candle/data/repositories/location_notes/location_note_repository.dart';
import 'package:candle/data/repositories/wikipedia/wikipedia_repository.dart';
import 'package:candle/data/services/attestation/attestation_service.dart';
import 'package:candle/data/services/candle_api/candle_api_client.dart';
import 'package:candle/data/services/candle_api/server_config_service.dart';
import 'package:candle/data/services/compass/compass_service.dart';
import 'package:candle/data/services/database/candle_database.dart';
import 'package:candle/data/services/feedback/vibration_service.dart';
import 'package:candle/data/services/language/language_service.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/data/services/nominatim/nominatim_client.dart';
import 'package:candle/data/services/ors/ors_client.dart';
import 'package:candle/data/services/overpass/overpass_client.dart';
import 'package:candle/data/services/permissions/permission_service.dart';
import 'package:candle/data/services/share/share_service.dart';
import 'package:candle/data/services/sharing/shared_content_service.dart';
import 'package:candle/data/services/shortcuts/app_shortcut_service.dart';
import 'package:candle/data/services/accessibility/accessibility_service.dart';
import 'package:candle/data/services/wikipedia/wikipedia_client.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:vibration/vibration.dart';

final _log = Logger();

/// Services and repositories available to the whole app.
List<SingleChildWidget> get providers => [
      Provider<http.Client>(create: (_) => http.Client(), dispose: (_, client) => client.close()),
      Provider(create: (context) => OverpassClient(client: context.read())),
      ChangeNotifierProvider(create: (_) => LanguageService()),
      Provider(create: (context) => NominatimClient(client: context.read())),
      Provider(
        create: (context) =>
            GeocodingRepository(nominatim: context.read(), language: context.read()),
      ),
      Provider(create: (_) => ShareService()),
      Provider(create: (_) => SharedContentService()),
      Provider(create: (_) => AppShortcutService()),
      Provider(create: (_) => AccessibilityService()),
      Provider(create: (_) => PermissionService()),
      Provider(create: (context) => WikipediaClient(client: context.read())),
      Provider(
        create: (context) =>
            WikipediaRepository(client: context.read(), language: context.read()),
      ),
      Provider(create: (context) => OrsClient(client: context.read())),
      Provider(create: (context) => RoutingRepository(ors: context.read())),
      Provider(create: (_) => LocationService()),
      Provider(create: (_) => CompassService()),
      Provider(create: (context) => VibrationService(settingsRepository: context.read())),
      Provider<PoiRepository>(create: (context) => PoiRepositoryRemote(overpass: context.read())),
      Provider(create: (_) => CandleDatabase(), dispose: (_, db) => db.close()),
      Provider(create: (context) => LocationRepository(database: context.read())),
      Provider(create: (context) => LocationNoteRepository(database: context.read())),
      Provider(
        create: (context) => LocationNoteAnnouncer(
          locationNoteRepository: context.read(),
          locationService: context.read(),
          settingsRepository: context.read(),
        ),
        dispose: (_, announcer) => announcer.dispose(),
      ),
      Provider(create: (context) => RouteRepository(database: context.read())),
      ChangeNotifierProvider(
        create: (context) => RecordingRepository(
          routeRepository: context.read(),
          locationService: context.read(),
          // A short vibration per recorded point tells the user that recording runs.
          onPointRecorded: () => Vibration.vibrate(duration: 100),
        ),
      ),
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
    ];
