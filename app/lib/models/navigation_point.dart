import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;

enum NavigationPointType {
  syntetic,
  routing,
}

class NavigationPoint {
  int? id;
  LatLng coordinate;
  String annotation;
  NavigationPointType type;

  NavigationPoint({
    this.id,
    required this.coordinate,
    required this.annotation,
    this.type = NavigationPointType.routing,
  });

  NavigationPoint copyWith({
    ValueGetter<int?>? id,
    LatLng? coordinate,
    String? annotation,
  }) {
    return NavigationPoint(
      id: id?.call() ?? this.id,
      coordinate: coordinate ?? this.coordinate,
      annotation: annotation ?? this.annotation,
    );
  }

  LatLng latlng() {
    return coordinate;
  }

  google.LatLng glatlng() {
    return google.LatLng(coordinate.latitude, coordinate.longitude);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coordinate': {'latitude': coordinate.latitude, 'longitude': coordinate.longitude},
      'annotation': annotation,
    };
  }

  factory NavigationPoint.fromMap(Map<String, dynamic> map) {
    return NavigationPoint(
      id: map['id']?.toInt(),
      coordinate: LatLng(map['coordinate']['latitude'], map['coordinate']['longitude']),
      annotation: map['annotation'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory NavigationPoint.fromJson(String source) => NavigationPoint.fromMap(json.decode(source));

  @override
  String toString() => 'NavigationPoint(id: $id, coordinate: $coordinate, annotation: $annotation)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NavigationPoint &&
        other.id == id &&
        other.coordinate == coordinate &&
        other.annotation == annotation;
  }

  @override
  int get hashCode => id.hashCode ^ coordinate.hashCode ^ annotation.hashCode;
}
