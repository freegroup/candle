import 'dart:convert';

import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/utils/result.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// openrouteservice.org API key, passed at build time:
//   flutter run --dart-define-from-file=env/dev.json
// Note: a key compiled into the app can be extracted. It moves to the
// Candle server in a later phase.
const String _orsApiKey = String.fromEnvironment('ORS_API_KEY');

/// Walking routes from openrouteservice.org.
class OrsClient {
  OrsClient({required this._client});

  final http.Client _client;

  /// The walking route from [start] to [end]; its first point is [start] itself.
  Future<Result<Route>> walkingRoute(LatLng start, LatLng end) async {
    try {
      final response = await _client.post(
        // api.openrouteservice.org is deprecated in favour of api.heigit.org (same key).
        Uri.https('api.heigit.org', '/openrouteservice/v2/directions/foot-walking/geojson'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_orsApiKey',
        },
        body: jsonEncode({
          'coordinates': [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude],
          ],
        }),
      );
      if (response.statusCode != 200) {
        return Result.error(http.ClientException('openrouteservice ${response.statusCode}'));
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final coordinates = (((json['features'] as List).first as Map<String, dynamic>)['geometry']
          as Map<String, dynamic>)['coordinates'] as List;
      return Result.ok(Route(name: 'current', points: [
        NavigationPoint(coordinate: start, annotation: ''),
        for (final coordinate in coordinates.cast<List<dynamic>>())
          NavigationPoint(
            coordinate: LatLng((coordinate[1] as num).toDouble(), (coordinate[0] as num).toDouble()),
            annotation: '',
          ),
      ]));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
