import 'dart:convert';

import 'package:candle/data/services/sharing/shared_content_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a shared place in the format of the share function', () {
    final content = parseCandleFile(jsonEncode({
      'locations': [
        {'id': null, 'name': 'Bakery', 'formattedAddress': 'Main Street 1', 'lat': 49.1, 'lon': 8.4},
      ],
    }));
    expect((content as SharedLocation).location.name, 'Bakery');
    expect(content.location.lat, 49.1);
  });

  test('reads a shared voice pin', () {
    final content = parseCandleFile(jsonEncode({
      'voicepins': [
        {'name': '', 'memo': 'Stairs', 'lat': 1.0, 'lon': 2.0, 'created': '2025-01-01T10:00:00.000'},
      ],
    }));
    expect((content as SharedLocationNote).pin.memo, 'Stairs');
  });

  test('ignores lists and foreign files', () {
    expect(parseCandleFile(jsonEncode({'locations': <Object>[]})), isNull);
    expect(parseCandleFile(jsonEncode({'something': 'else'})), isNull);
    expect(parseCandleFile('[1, 2]'), isNull);
  });

  test('understands short Google Maps links only', () {
    expect(parseSharedText('https://maps.app.goo.gl/abc'), isA<SharedMapsLink>());
    expect(parseSharedText('hello'), isNull);
  });
}
