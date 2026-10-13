import 'package:candle/data/repositories/geocoding/geocoding_repository.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/domain/models/poi.dart';
import 'package:candle/utils/result.dart';

/// Converts a place into an address that can be saved or shared, with [name]
/// and [formattedAddress] as the app shows them. Places without a complete
/// OSM address are reverse geocoded with [geocoding].
Future<LocationAddress> poiToLocationAddress(
  Poi poi, {
  required GeocodingRepository geocoding,
  required String name,
  required String formattedAddress,
}) async {
  if (!poi.hasAddress) {
    final address = await geocoding.addressAt(poi.position);
    if (address is Ok<LocationAddress>) {
      return address.value
          .copyWith(name: name, lat: poi.position.latitude, lon: poi.position.longitude);
    }
  }
  return LocationAddress(
    name: name,
    formattedAddress: formattedAddress,
    street: poi.street,
    number: poi.number,
    zip: poi.zip,
    city: poi.city,
    country: '',
    lat: poi.position.latitude,
    lon: poi.position.longitude,
  );
}
