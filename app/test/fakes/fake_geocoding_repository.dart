import 'package:candle/data/repositories/geocoding/geocoding_repository.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

class FakeGeocodingRepository implements GeocodingRepository {
  LocationAddress? address;
  List<LocationAddress> searchResults = [];

  @override
  Future<Result<LocationAddress>> addressAt(LatLng position) async =>
      address == null ? Result.error(Exception('no address')) : Result.ok(address!);

  @override
  Future<Result<List<LocationAddress>>> search(String query, {required String languageCode}) async =>
      Result.ok(searchResults);
}
