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

      // because sometimes be get a poi twice with differnet distances....we keep
      // only one.

      // A map to store the closest poi by name
      Map<String, PoiDetail> closestPoisByName = {};

      // Populate the map with the closest pois
      for (final poi in pois) {
        double distance = calculateDistance(poi.latlng, nearby_coords);
        if (!closestPoisByName.containsKey(poi.name) ||
            distance < calculateDistance(closestPoisByName[poi.name]!.latlng, nearby_coords)) {
          closestPoisByName[poi.name] = poi;
        }
      }

      // Remove duplicates from the list
      List<PoiDetail> uniquePois = [];
      for (final poi in pois) {
        PoiDetail closestPoi = closestPoisByName[poi.name]!;
        double distanceToClosestPoi = calculateDistance(closestPoi.latlng, nearby_coords);
        double distanceToCurrentPoi = calculateDistance(poi.latlng, nearby_coords);

        if (distanceToCurrentPoi == distanceToClosestPoi) {
          uniquePois.add(poi);
        }
      }

      return uniquePois;
    } catch (e) {
      // Handle exceptions
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
