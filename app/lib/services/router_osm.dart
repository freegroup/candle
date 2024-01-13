import 'dart:convert';

import 'package:candle/auth/secrets.dart';
import 'package:candle/models/navigation_point.dart' as model;
import 'package:candle/models/route.dart' as model;
import 'package:candle/services/router.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OSMRoutingService implements RoutingService {
  @override
  Future<model.Route?> getPedestrianRoute(LatLng start, LatLng end) async {
    var client = http.Client();

    try {
      var url = 'https://api.openrouteservice.org/v2/directions/foot-walking/geojson';
      var headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $OPENSTREETMAP_API_KEY'
      };
      var body = json.encode({
        'coordinates': [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude]
        ]
      });

      var response = await client.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var routeLatLng = [
          for (var coord in data['features'][0]['geometry']['coordinates'])
            model.NavigationPoint(coordinate: LatLng(coord[1], coord[0]), annotation: '')
        ];
        routeLatLng.insert(0, model.NavigationPoint(annotation: "", coordinate: start));
        var route = model.Route(name: "current", points: routeLatLng);
        //return route.calculateWaypointRoute();
        return route;
      } else {
        log.e('Failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      log.e('Error occurred during fetching pedestrian route: $e');
    } finally {
      client.close();
    }
    return null;
  }
}
