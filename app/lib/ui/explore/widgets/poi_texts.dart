import 'package:candle/domain/models/poi.dart';
import 'package:candle/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Localized labels and icons for the explore feature.
extension PoiTexts on AppLocalizations {
  String poiCategoryTitle(PoiCategory category) => switch (category) {
        PoiCategory.crossings => poi_category_crossing,
        PoiCategory.bars => poi_category_bars,
        PoiCategory.atms => poi_category_atms,
        PoiCategory.restaurants => poi_category_restaurants,
        PoiCategory.hospitals => poi_category_hospitals,
        PoiCategory.cafes => poi_category_cafes,
        PoiCategory.busStations => poi_category_bus_stations,
        PoiCategory.taxis => poi_category_taxis,
        PoiCategory.pharmacies => poi_category_pharmacies,
        PoiCategory.audibleSignals => poi_category_audible_signals,
        PoiCategory.publicToilets => poi_category_public_toilets,
      };

  String poiName(Poi poi) => switch (poi.kind) {
        PoiKind.named => poi.name,
        PoiKind.crossingTrafficSignals => crossing_traffic_signal,
        PoiKind.crossingZebra => crossing_rebra_marking,
        PoiKind.crossingIsland => crossing_with_island,
        PoiKind.crossingUnmarked => crossing_unmarked,
        PoiKind.audibleSignal => poi_audible_signal,
      };

  /// Short address, empty if OSM has no complete address for the place.
  String poiAddress(Poi poi) =>
      poi.hasAddress ? formated_address_short(poi.street, poi.number, poi.city) : '';
}

IconData poiCategoryIcon(PoiCategory category) => switch (category) {
      PoiCategory.crossings => Icons.transfer_within_a_station,
      PoiCategory.bars => Icons.local_drink,
      PoiCategory.atms => Icons.local_atm,
      PoiCategory.restaurants => Icons.restaurant,
      PoiCategory.hospitals => Icons.local_hospital,
      PoiCategory.cafes => Icons.local_cafe,
      PoiCategory.busStations => Icons.directions_bus,
      PoiCategory.taxis => Icons.local_taxi,
      PoiCategory.pharmacies => Icons.local_pharmacy,
      PoiCategory.audibleSignals => Icons.hearing,
      PoiCategory.publicToilets => Icons.wc,
    };
