import 'package:candle/utils/geo.dart';
import 'package:test/test.dart';

void main() {
  test('Geolocation address lookup', () async {
    double latitude =  49.45622156121109; // Example latitude (Berlin)
    double longitude = 8.596111485518252; // Example longitude (Berlin)

    final address = await getGeolocationAddress(latitude, longitude);
    print(address); // For demonstration purposes

    // Check if the address is not null
    expect(address, isNotNull);
    // You can add more specific tests here, like checking if the address contains certain strings
  });
}
