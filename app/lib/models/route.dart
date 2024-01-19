import 'dart:convert';
import 'dart:math' as math;
import 'package:candle/utils/geo.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:xml/xml.dart' as xml;

import 'package:candle/models/navigation_point.dart';
import 'package:latlong2/latlong.dart';

class Route {
  int? id;
  String name;
  String annotation;
  List<NavigationPoint> points;

  Route({
    this.id,
    required this.name,
    this.annotation = "",
    required this.points,
  });

  Route calculateWaypointRoute() {
    const double minSegmentLength = 15;
    const double distanceToInsert = 10;

    List<NavigationPoint> modifiedPoints = [];

    for (int i = 0; i < points.length; i++) {
      NavigationPoint currentPoi = points[i];
      List<NavigationPoint?> adjacentPois = findAdjacentPoint(currentPoi);
      NavigationPoint? prevPoi = adjacentPois[0];
      NavigationPoint? nextPoi = adjacentPois[1];

      // Add extra previous point
      if (prevPoi != null && isSpecialCoordinate(currentPoi)) {
        double prevSegmentLength = calculateDistance(currentPoi.coordinate, prevPoi.coordinate);
        if (prevSegmentLength > minSegmentLength) {
          // Calculate and insert extra previous point
          NavigationPoint extraPrevPoi = interpolate(
            start: currentPoi,
            end: prevPoi,
            distance: distanceToInsert,
          );
          modifiedPoints.add(extraPrevPoi);
        }
      }

      // Add the current point
      modifiedPoints.add(currentPoi);

      // Add extra next point
      if (nextPoi != null && isSpecialCoordinate(currentPoi)) {
        double nextSegmentLength = calculateDistance(currentPoi.coordinate, nextPoi.coordinate);
        if (nextSegmentLength > minSegmentLength) {
          // Calculate and insert extra next point
          NavigationPoint extraNextPoi = interpolate(
            start: currentPoi,
            end: nextPoi,
            distance: distanceToInsert,
          );
          modifiedPoints.add(extraNextPoi);
        }
      }
    }

    return Route(name: name, points: modifiedPoints);
  }

  Map<String, dynamic> findClosestSegment(LatLng coord) {
    double minDistance = double.infinity;
    int? closestSegmentStartIndex;

    for (int i = 0; i < points.length - 1; i++) {
      NavigationPoint startCoord = points[i];
      NavigationPoint endCoord = points[i + 1];

      // Calculate the distance from the poi to the line segment
      double currentDistance = distanceToSegment(
        point: coord,
        start: startCoord.coordinate,
        end: endCoord.coordinate,
      );
      if (currentDistance < minDistance) {
        minDistance = currentDistance;
        closestSegmentStartIndex = i;
      }
    }

    if (closestSegmentStartIndex == null) {
      throw ArgumentError("Could not find closest segment.");
    }

    int closestSegmentEndIndex = closestSegmentStartIndex + 1;
    return {
      "distance": minDistance,
      "start": {"index": closestSegmentStartIndex, "coord": points[closestSegmentStartIndex]},
      "end": {"index": closestSegmentEndIndex, "coord": points[closestSegmentEndIndex]},
    };
  }

  double calculateTotalLength() {
    double totalLength = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      totalLength += calculateDistance(
        points[i].coordinate,
        points[i + 1].coordinate,
      );
    }

    return totalLength;
  }

  double calculateResumingLengthFromWaypoint(NavigationPoint currentWaypoint) {
    int waypointIndex = points.indexOf(currentWaypoint);
    if (waypointIndex == -1 || waypointIndex == points.length - 1) {
      // If the current waypoint is not in the list or it is the last point
      return 0.0;
    }

    double totalDistance = 0.0;
    for (int i = waypointIndex; i < points.length - 1; i++) {
      totalDistance += calculateDistance(points[i].coordinate, points[i + 1].coordinate);
    }

    return totalDistance;
  }

  double calculateAngle(NavigationPoint p2) {
    List<NavigationPoint?> adjacentPoints = findAdjacentPoint(p2);

    // Check if adjacent points exist and the list has exactly two elements
    if (adjacentPoints.length != 2 || adjacentPoints.any((point) => point == null)) {
      return 0.0;
    }

    NavigationPoint p1 = adjacentPoints[0]!;
    NavigationPoint p3 = adjacentPoints[1]!;

    // Calculate distances between the points
    double a = calculateDistance(p2.coordinate, p3.coordinate);
    double b = calculateDistance(p1.coordinate, p3.coordinate);
    double c = calculateDistance(p1.coordinate, p2.coordinate);

    // Apply the Law of Cosines to find the angle at p2
    double cosAngle = (math.pow(a, 2) + math.pow(c, 2) - math.pow(b, 2)) / (2 * a * c);
    cosAngle = math.max(-1, math.min(1, cosAngle));
    double angle = math.acos(cosAngle) * (180 / math.pi);

    return angle;
  }

  bool isSpecialCoordinate(NavigationPoint poi) {
    /// Decides whenever the coordinate is special. Special in the sense of pedestrian navigation.
    /// In this case, the point needs some vertex in front and behind of them.
    double angle = calculateAngle(poi);
    return 60 <= angle && angle <= 120;
  }

  List<NavigationPoint?> findAdjacentPoint(NavigationPoint poi) {
    int currentIdx = points.indexWhere((p) => p == poi);

    NavigationPoint? prevPoi;
    NavigationPoint? nextPoi;

    if (currentIdx != -1) {
      prevPoi = currentIdx > 0 ? points[currentIdx - 1] : null;
      nextPoi = currentIdx < points.length - 1 ? points[currentIdx + 1] : null;
    }

    return [prevPoi, nextPoi]; // Return as a list
  }

  NavigationPoint interpolate({
    required NavigationPoint start,
    required NavigationPoint end,
    required double distance,
    NavigationPointType type = NavigationPointType.syntetic, // Default to synthetic
  }) {
    var from = start.coordinate;
    var to = end.coordinate;
    const Distance calculator = Distance();
    final double totalDistance = calculator.as(
      LengthUnit.Meter,
      start.coordinate,
      end.coordinate,
    );

    final double latOffset = (to.latitude - from.latitude) * (distance / totalDistance);
    final double lonOffset = (to.longitude - from.longitude) * (distance / totalDistance);

    return NavigationPoint(
      coordinate: LatLng(from.latitude + latOffset, from.longitude + lonOffset),
      annotation: "",
      type: type, // Set the type
    );
  }

  String toGPX() {
    var builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('gpx', nest: () {
      builder.attribute('version', '1.1');
      builder.attribute('creator', 'YourAppName'); // Replace with your app name
      builder.element('trk', nest: () {
        builder.element('name', nest: name);
        builder.element('trkseg', nest: () {
          for (var point in points) {
            builder.element('trkpt', nest: () {
              builder.attribute('lat', point.coordinate.latitude.toString());
              builder.attribute('lon', point.coordinate.longitude.toString());
              builder.element('ele', nest: '0'); // Elevation, set to 0 if not available
              builder.element('time',
                  nest: DateTime.now()
                      .toIso8601String()); // Current time, replace if actual time data is available
            });
          }
        });
      });
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }

  // Convert the list of NavigationPoints to a JSON string
  String pointsToJson() => json.encode(points.map((x) => x.toMap()).toList());

  // Convert a JSON string to a list of NavigationPoints
  static List<NavigationPoint> pointsFromJson(String jsonString) =>
      List<NavigationPoint>.from(json.decode(jsonString).map((x) => NavigationPoint.fromMap(x)));

  Route copyWith({
    ValueGetter<int?>? id,
    String? name,
    String? annotation,
    List<NavigationPoint>? points,
  }) {
    return Route(
      id: id?.call() ?? this.id,
      name: name ?? this.name,
      annotation: annotation ?? this.annotation,
      points: points ?? this.points,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'annotation': annotation,
      'points': points.map((x) => x.toMap()).toList(),
    };
  }

  factory Route.fromMap(Map<String, dynamic> map) {
    return Route(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      annotation: map['annotation'] ?? '',
      points: map['points'] != null ? Route.pointsFromJson(map['points']) : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Route.fromJson(String source) => Route.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Route(id: $id, name: $name, annotation: $annotation, points: $points)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Route &&
        other.id == id &&
        other.name == name &&
        other.annotation == annotation &&
        listEquals(other.points, points);
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ annotation.hashCode ^ points.hashCode;
  }
}
