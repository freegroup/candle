import 'package:candle/services/poi_provider_overpass.dart';
import 'package:candle/utils/geo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

class PoiDetail {
  String name;
  LatLng latlng;
  String street;
  String number;
  String city;
  String zip;
  PoiDetail({
    required this.name,
    required this.latlng,
    this.street = "",
    this.number = "",
    this.city = "",
    this.zip = "",
  });

  String formattedAddress(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return (street.isEmpty || number.isEmpty || city.isEmpty)
        ? ""
        : l10n.formated_address_short(street, number, city);
  }
}

class PoiProvider extends ChangeNotifier {
  final PoiProviderOverpass _poiLookupProvider = PoiProviderOverpass();

  Future<List<PoiDetail>> fetchPois(
      List<String> categories, int radiusInMeter, LatLng nearbyCoords) async {
    try {
      List<PoiDetail> pois =
          await _poiLookupProvider.fetchPoi(categories, radiusInMeter, nearbyCoords);
      pois.sort((a, b) => calculateDistance(a.latlng, nearbyCoords)
          .compareTo(calculateDistance(b.latlng, nearbyCoords)));

      // because sometimes be get a poi twice with differnet distances....we keep
      // only one.

      // A map to store the closest poi by name
      Map<String, PoiDetail> closestPoisByName = {};

      // Populate the map with the closest pois
      for (final poi in pois) {
        double distance = calculateDistance(poi.latlng, nearbyCoords);
        if (!closestPoisByName.containsKey(poi.name) ||
            distance < calculateDistance(closestPoisByName[poi.name]!.latlng, nearbyCoords)) {
          closestPoisByName[poi.name] = poi;
        }
      }

      // Remove duplicates from the list
      List<PoiDetail> uniquePois = [];
      for (final poi in pois) {
        PoiDetail closestPoi = closestPoisByName[poi.name]!;
        double distanceToClosestPoi = calculateDistance(closestPoi.latlng, nearbyCoords);
        double distanceToCurrentPoi = calculateDistance(poi.latlng, nearbyCoords);

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
