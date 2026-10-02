import 'package:candle/data/services/language/language_service.dart';
import 'package:candle/data/services/nominatim/nominatim_client.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

/// Turns positions into addresses and searches addresses.
class GeocodingRepository {
  GeocodingRepository({required this._nominatim, required this._language});

  final NominatimClient _nominatim;
  final LanguageService _language;
  final _addresses = <LatLng, LocationAddress>{};

  /// The address at [position]; repeated lookups of a position are answered from memory.
  Future<Result<LocationAddress>> addressAt(LatLng position) async {
    if (_addresses[position] case final cached?) return Result.ok(cached);
    final result = await _nominatim.reverse(position);
    if (result case Ok(:final value)) _addresses[position] = value;
    return result;
  }

  /// Addresses matching [query], named in the language of the app.
  Future<Result<List<LocationAddress>>> search(String query) =>
      _nominatim.search(query, _language.languageCode);
}
