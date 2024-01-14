import 'package:candle/services/poi_provider.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';

// We will use this util class to fetch the auto complete result and get the details of the place.
class PoiProviderOverpass {
  PoiProviderOverpass();

  Future<List<PoiDetail>> fetchPoi(List<String> categories, int radiusInMeter, LatLng coord) async {
    String nodes = categories
        .map((category) => '$category(around:$radiusInMeter,${coord.latitude},${coord.longitude});')
        .join('\n  ');

    String overpassQuery = '[out:json];\n($nodes\n);\nout center;';

    var response = await http.get(
      Uri.parse(
          'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}'),
    );
    if (response.statusCode == 200) {
      String bodyUtf8 = utf8.decode(response.bodyBytes);
      var data = json.decode(bodyUtf8);
      List<PoiDetail> pois = [];

      if (data['elements'] != null) {
        for (var element in data['elements']) {
          // Skip if the 'name' tag does not exist or is empty
          if (element['tags'] != null &&
              element['tags']['name'] != null &&
              element['tags']['name'].isNotEmpty) {
            pois.add(PoiDetail(
              name: element['tags']['name'],
              latlng: LatLng(element['lat'], element['lon']),
            ));
          }
        }
      }

      return pois;
    } else {
      throw Exception('Failed to load POIs');
    }
  }
}
