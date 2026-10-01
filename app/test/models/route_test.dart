import 'package:candle/domain/models/navigation_point.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/utils/geo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

NavigationPoint p(double lat, double lon) =>
    NavigationPoint(coordinate: LatLng(lat, lon), annotation: '');

void main() {
  // An L-shaped route: ~222 m east, then ~222 m north (right angle at b).
  final a = p(52.5163, 13.3777);
  final b = p(52.5163, 13.3810);
  final c = p(52.5183, 13.3810);
  Route lRoute() => Route(name: 'L', points: [a, b, c]);

  test('calculateTotalLength sums the segments', () {
    final route = lRoute();
    final expected = calculateDistance(a.coordinate, b.coordinate) +
        calculateDistance(b.coordinate, c.coordinate);
    expect(route.calculateTotalLength(), closeTo(expected, 0.001));
  });

  test('calculateResumingLengthFromWaypoint', () {
    final route = lRoute();
    expect(route.calculateResumingLengthFromWaypoint(b),
        closeTo(calculateDistance(b.coordinate, c.coordinate), 0.001));
    expect(route.calculateResumingLengthFromWaypoint(c), 0);
  });

  test('calculateAngle is ~90° at the corner and 0 at the ends', () {
    final route = lRoute();
    expect(route.calculateAngle(b), closeTo(90, 2));
    expect(route.calculateAngle(a), 0);
    expect(route.calculateAngle(c), 0);
  });

  test('the corner is a special coordinate, the ends are not', () {
    final route = lRoute();
    expect(route.isSpecialCoordinate(b), isTrue);
    expect(route.isSpecialCoordinate(a), isFalse);
  });

  test('calculateWaypointRoute inserts synthetic points around the corner', () {
    final result = lRoute().calculateWaypointRoute();
    expect(result.points.length, 5);
    expect(result.points[1].type, NavigationPointType.syntetic);
    expect(result.points[3].type, NavigationPointType.syntetic);
    expect(calculateDistance(result.points[1].coordinate, b.coordinate), closeTo(10, 0.5));
    expect(calculateDistance(result.points[3].coordinate, b.coordinate), closeTo(10, 0.5));
  });

  test('findClosestSegment returns the nearest segment', () {
    final route = lRoute();
    final closest = route.findClosestSegment(const LatLng(52.5173, 13.3812));
    expect((closest['start'] as Map)['index'], 1);
    expect((closest['end'] as Map)['index'], 2);
  });
}
