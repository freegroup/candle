import 'package:candle/data/services/overpass/overpass_client.dart';
import 'package:candle/services/poi_provider.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';
import 'package:candle/l10n/app_localizations.dart';

// Legacy adapter for the radar screen; the explore feature uses PoiRepository.
class PoiProviderOverpass {
  PoiProviderOverpass(this._overpass);

  final OverpassClient _overpass;

  Future<List<PoiDetail>> fetchPoi(
      AppLocalizations l10n, List<String> categories, int radiusInMeter, LatLng coord) async {
    String nodes = categories
        .map((category) => '$category(around:$radiusInMeter,${coord.latitude},${coord.longitude});')
        .join('\n  ');

    final result = await _overpass.query('[out:json];\n($nodes\n);\nout center;');
    if (result is! Ok) throw Exception('Failed to load POIs');

    List<PoiDetail> pois = [];
    for (final element in (result as Ok).value) {
      final tags = element.tags;
      String name = _getNodeName(l10n, {'tags': tags});
      if (name.isNotEmpty) {
        pois.add(PoiDetail(
          name: name,
          latlng: LatLng(element.lat, element.lon),
          street: tags['addr:street'] ?? "",
          number: tags['addr:housenumber'] ?? '',
          zip: tags['addr:postcode'] ?? '',
          city: tags['addr:city'] ?? "",
        ));
      }
    }
    return pois;
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

      if (tags['crossing:island'] == 'yes') {
        return l10n.crossing_with_island;
      }

      // If it's a crossing but doesn't fit the above categories
      return l10n.crossing_unmarked;
    }

    return tags['name'] ?? '';
  }
}
