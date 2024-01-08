import 'package:candle/services/poi_provider_overpass.dart';
import 'package:candle/utils/geo.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class PoiDetail {
  String name;
  LatLng latlng;

  PoiDetail({
    required this.name,
    required this.latlng,
  });
}

class PoiProvider extends ChangeNotifier {
  final PoiProviderOverpass _poiLookupProvider = PoiProviderOverpass();

  Future<List<PoiDetail>> fetchPois(
      List<String> categories, int radiusInMeter, LatLng nearby_coords) async {
    try {
      List<PoiDetail> pois =
          await _poiLookupProvider.fetchPoi(categories, radiusInMeter, nearby_coords);
      pois.sort((a, b) => calculateDistance(a.latlng, nearby_coords)
          .compareTo(calculateDistance(b.latlng, nearby_coords)));

      return pois;
    } catch (e) {
      // Handle exceptions
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
