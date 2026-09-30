import 'package:candle/data/repositories/poi/poi_repository.dart';
import 'package:candle/data/repositories/poi/poi_repository_remote.dart';
import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/data/services/overpass/overpass_client.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/poi_provider.dart';
import 'package:candle/services/router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Services and repositories available to the whole app.
List<SingleChildWidget> get providers => [
      Provider<http.Client>(create: (_) => http.Client(), dispose: (_, client) => client.close()),
      Provider(create: (context) => OverpassClient(client: context.read())),
      Provider(create: (_) => LocationService()),
      Provider<PoiRepository>(create: (context) => PoiRepositoryRemote(overpass: context.read())),

      // Legacy services, removed while the screens are migrated.
      ChangeNotifierProvider(create: (_) => GeoServiceProvider()),
      ChangeNotifierProvider(create: (context) => PoiProvider(context.read())),
      ChangeNotifierProvider(create: (_) => RoutingProvider()),
    ];
