import 'package:candle/data/repositories/poi/poi_repository.dart';
import 'package:candle/domain/models/poi.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

class FakePoiRepository implements PoiRepository {
  FakePoiRepository(this.result);

  Result<List<Poi>> result;
  int calls = 0;

  @override
  Future<Result<List<Poi>>> findNearby(PoiCategory category, LatLng center,
      {int radiusInMeter = 2000}) async {
    calls++;
    return result;
  }
}
