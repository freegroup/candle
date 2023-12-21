import 'dart:convert';

import 'package:flutter/widgets.dart';

class Location {
  final int? id;
  final String name;
  final double lat;
  final double lon;
  Location({
    this.id,
    required this.name,
    required this.lat,
    required this.lon,
  });

  Location copyWith({
    ValueGetter<int?>? id,
    String? name,
    double? lat,
    double? lon,
  }) {
    return Location(
      id: id?.call() ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lon': lon,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      lat: map['lat']?.toDouble() ?? 0.0,
      lon: map['lon']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Location.fromJson(String source) => Location.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Location(id: $id, name: $name, lat: $lat, lon: $lon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Location &&
        other.id == id &&
        other.name == name &&
        other.lat == lat &&
        other.lon == lon;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ lat.hashCode ^ lon.hashCode;
  }
}
