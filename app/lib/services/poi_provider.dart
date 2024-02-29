import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:candle/models/latlng_provider.dart';
import 'package:candle/models/location_address.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/poi_provider_overpass.dart';
import 'package:candle/utils/geo.dart';

class PoiDetail implements LatLngProvider{
  String name;
  late LatLng _latlng;
  String street;
  String number;
  String city;
  String zip;
  PoiDetail({
    required this.name,
    required latlng,
    this.street = "",
    this.number = "",
    this.city = "",
    this.zip = "",
  }){
    _latlng = latlng;
  }

  String formattedAddress(AppLocalizations l10n) {
    return (street.isEmpty || number.isEmpty || city.isEmpty)
        ? ""
        : l10n.formated_address_short(street, number, city);
  }

  Future<LocationAddress> toLocationAddress(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    // do a GeoCoder lookup to fetch the required formatedAddress of the poi
    // do not provide one
    if (street.isEmpty || number.isEmpty || city.isEmpty) {
      var geo = Provider.of<GeoServiceProvider>(context, listen: false).service;
      var address = await geo.getGeolocationAddress(_latlng);
      if (address != null) {
        return address.copyWith(name: name, lat: _latlng.latitude, lon: _latlng.longitude);
      }
    }
    return LocationAddress(
      name: name,
      formattedAddress: formattedAddress(l10n),
      street: street,
      number: number,
      zip: zip,
      city: city,
      country: "",
      lat: _latlng.latitude,
      lon: _latlng.longitude,
    );
  }
  
  @override
  LatLng latlng() {
    return _latlng;
  }
}

class PoiProvider extends ChangeNotifier {
  final PoiProviderOverpass _poiLookupProvider = PoiProviderOverpass();

  Future<List<PoiDetail>> fetchPois(
    AppLocalizations l10n,
    List<String> categories,
    int radiusInMeter,
    LatLng nearbyCoords,
  ) async {
    try {
      List<PoiDetail> pois =
          await _poiLookupProvider.fetchPoi(l10n, categories, radiusInMeter, nearbyCoords);
      pois.sort((a, b) => calculateDistance(a.latlng(), nearbyCoords)
          .compareTo(calculateDistance(b.latlng(), nearbyCoords)));

      // because sometimes be get a poi twice with differnet distances....we keep
      // only one.

      // A map to store the closest poi by name
      Map<String, PoiDetail> closestPoisByName = {};

      // Populate the map with the closest pois
      for (final poi in pois) {
        double distance = calculateDistance(poi.latlng(), nearbyCoords);
        if (!closestPoisByName.containsKey(poi.name) ||
            distance < calculateDistance(closestPoisByName[poi.name]!.latlng(), nearbyCoords)) {
          closestPoisByName[poi.name] = poi;
        }
      }

      // Remove duplicates from the list
      List<PoiDetail> uniquePois = [];
      for (final poi in pois) {
        PoiDetail closestPoi = closestPoisByName[poi.name]!;
        double distanceToClosestPoi = calculateDistance(closestPoi.latlng(), nearbyCoords);
        double distanceToCurrentPoi = calculateDistance(poi.latlng(), nearbyCoords);

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
