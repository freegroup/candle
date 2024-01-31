import 'package:candle/services/poi_provider.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// We will use this util class to fetch the auto complete result and get the details of the place.
class PoiProviderOverpass {
  PoiProviderOverpass();

  Future<List<PoiDetail>> fetchPoi(
      AppLocalizations l10n, List<String> categories, int radiusInMeter, LatLng coord) async {
    String nodes = categories
        .map((category) => '$category(around:$radiusInMeter,${coord.latitude},${coord.longitude});')
        .join('\n  ');

    String overpassQuery = '[out:json];\n($nodes\n);\nout center;';
    //print(overpassQuery);
    overpassQuery = Uri.encodeComponent(overpassQuery);

    Uri overpassUri = Uri.parse('https://overpass-api.de/api/interpreter?data=$overpassQuery');
    var response = await http.get(overpassUri);

    if (response.statusCode == 200) {
      String bodyUtf8 = utf8.decode(response.bodyBytes);
      var data = json.decode(bodyUtf8);
      List<PoiDetail> pois = [];

      if (data['elements'] != null) {
        for (var element in data['elements']) {
          if (element['tags'] != null) {
            String name = _getNodeName(l10n, element);
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

  String _getNodeName(AppLocalizations l10n, Map<String, dynamic> element) {
    var tags = element['tags'];
    if (tags == null) {
      return "";
    }

    // Special case for Crossings. They do not have a name. Generate one
    //
    if (tags.containsKey('crossing') || tags['highway'] == "crossing") {
      // Assuming 'tactile_paving' tag with 'yes' value indicates tactile support
      if (tags['crossing'] == 'traffic_signals') {
        return l10n.crossing_traffic_signal;
      }

      if (tags['crossing:markings'] == 'zebra') {
        return l10n.crossing_rebra_marking;
      }

      if (tags['rossing:island'] == 'yes') {
        return l10n.crossing_with_island;
      }

      // If it's a crossing but doesn't fit the above categories
      return l10n.crossing_unmarked;
    }

    return tags['name'] ?? '';
  }
}
