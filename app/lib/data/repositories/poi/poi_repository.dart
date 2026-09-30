import 'package:candle/domain/models/poi.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

abstract class PoiRepository {
  /// Places of [category] within [radiusInMeter] around [center],
  /// sorted by distance (closest first).
  Future<Result<List<Poi>>> findNearby(
    PoiCategory category,
    LatLng center, {
    int radiusInMeter,
  });
}
