import 'package:candle/data/services/sharing/candle_link.dart';
import 'package:candle/data/services/sharing/shared_content_service.dart';
import 'package:candle/domain/models/location_address.dart';
import 'package:candle/domain/models/location_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final address = LocationAddress(
      name: 'Home', formattedAddress: 'Main Street 1', street: 'Main Street', number: '1',
      zip: '', city: 'Town', country: '', lat: 52.5163, lon: 13.3777);
  final note = LocationNote(name: 'x', memo: 'Stairs after the door', lat: 1.0, lon: 2.0);

  test('a location survives the round trip through a link', () {
    final uri = buildShareUri({'locations': [address.toMap()]});
    expect(uri.host, candleLinkHost);
    expect(uri.path, startsWith(candleLinkPathPrefix));
    final content = parseShareUri(uri);
    expect(content, isA<SharedLocation>());
    expect((content! as SharedLocation).location.name, 'Home');
  });

  test('a location note survives the round trip through a link', () {
    final content = parseShareUri(buildShareUri({'voicepins': [note.toMap()]}));
    expect(content, isA<SharedLocationNote>());
    expect((content! as SharedLocationNote).pin.memo, 'Stairs after the door');
  });

  test('foreign or broken links return null', () {
    expect(parseShareUri(Uri.parse('https://example.com/candle/share/?d=abc')), isNull);
    expect(parseShareUri(Uri.parse('https://freegroup.de/candle/share/')), isNull);
    expect(parseShareUri(Uri.parse('https://freegroup.de/candle/share/?d=%%%not-base64')), isNull);
  });
}
