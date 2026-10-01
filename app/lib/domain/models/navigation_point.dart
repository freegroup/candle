import 'package:candle/domain/models/latlng_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

enum NavigationPointType {
  syntetic,
  routing,
}

class NavigationPoint implements LatLngProvider {
  final int? id;
  final LatLng coordinate;
  final String annotation;
  final NavigationPointType type;

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

  @override
  LatLng latlng() {
    return coordinate;
  }

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
