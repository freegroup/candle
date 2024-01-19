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

    String overpassQuery = Uri.encodeComponent('[out:json];\n($nodes\n);\nout center;');
    Uri overpassUri = Uri.parse('https://overpass-api.de/api/interpreter?data=$overpassQuery');
    var response = await http.get(overpassUri);

    if (response.statusCode == 200) {
      String bodyUtf8 = utf8.decode(response.bodyBytes);
      var data = json.decode(bodyUtf8);
      List<PoiDetail> pois = [];

      if (data['elements'] != null) {
        for (var element in data['elements']) {
          if (element['tags'] != null) {
            String name = element['tags']['name'] ?? '';
            if (name.isNotEmpty) {
              Map<String, dynamic> tags = element['tags'];

              pois.add(PoiDetail(
                name: name,
                latlng: LatLng(element['lat'], element['lon']),
                street: tags['addr:street'] ?? "",
                number: tags['addr:housenumber'] ?? '',
                zip: tags['addr:postcode'] ?? '',
                city: tags['addr:city'] ?? "",
              ));
            }
          }
        }
      }

      return pois;
    } else {
      throw Exception('Failed to load POIs');
    }
  }
}
