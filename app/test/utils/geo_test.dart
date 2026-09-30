import 'package:candle/utils/geo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const origin = LatLng(52.5163, 13.3777); // Brandenburger Tor

  group('calculateNorthBearing', () {
    test('points north, east, south and west', () {
      expect(calculateNorthBearing(origin, const LatLng(52.5263, 13.3777)), 0);
      expect(calculateNorthBearing(origin, const LatLng(52.5163, 13.3877)), 89);
      expect(calculateNorthBearing(origin, const LatLng(52.5063, 13.3777)), 180);
      expect(calculateNorthBearing(origin, const LatLng(52.5163, 13.3677)), 270);
    });

    test('is always within 0..359', () {
      final bearing = calculateNorthBearing(origin, const LatLng(52.5, 13.3));
      expect(bearing, inInclusiveRange(0, 359));
    });
  });

  group('calculateDistance', () {
    test('is zero for the same point', () {
      expect(calculateDistance(origin, origin), 0);
    });

    test('0.001° latitude is about 111 m', () {
      expect(calculateDistance(origin, const LatLng(52.5173, 13.3777)), closeTo(111, 1));
    });
  });

  group('distanceToSegment', () {
    const start = LatLng(52.5163, 13.3777);
    const end = LatLng(52.5163, 13.3877);

    test('perpendicular distance to the middle of the segment', () {
      final d = distanceToSegment(point: const LatLng(52.5173, 13.3827), start: start, end: end);
      expect(d, closeTo(111, 1));
    });

    test('before the start it is the distance to the start', () {
      const point = LatLng(52.5163, 13.3677);
      expect(distanceToSegment(point: point, start: start, end: end),
          closeTo(calculateDistance(point, start), 0.01));
    });

    test('after the end it is the distance to the end', () {
      const point = LatLng(52.5163, 13.3977);
      expect(distanceToSegment(point: point, start: start, end: end),
          closeTo(calculateDistance(point, end), 0.01));
    });

    test('degenerate segment (start == end) does not divide by zero', () {
      final d = distanceToSegment(point: const LatLng(52.5173, 13.3777), start: start, end: start);
      expect(d.isFinite, isTrue);
    });
  });
}
