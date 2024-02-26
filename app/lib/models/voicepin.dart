import 'dart:convert';
import 'package:candle/models/latlng_provider.dart';
import 'package:candle/utils/geo.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

class VoicePin implements LatLngProvider {
  int? id;
  final String name;
  final String memo;
  final double lat;
  final double lon;
  final DateTime? created; // Optional timestamp

  VoicePin({
    this.id,
    required this.name,
    required this.memo,
    required this.lat,
    required this.lon,
    this.created, // Optional
  });

  @override
  LatLng latlng() {
    return LatLng(lat, lon);
  }

  VoicePin copyWith({
    ValueGetter<int?>? id,
    String? name,
    String? memo,
    double? lat,
    double? lon,
    DateTime? created,
  }) {
    return VoicePin(
      id: (id != null) ? id.call() : this.id,
      name: name ?? this.name,
      memo: memo ?? this.memo,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      created: created ?? this.created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'memo': memo,
      'lat': lat,
      'lon': lon,
      'created': created?.toIso8601String(), // Convert DateTime to ISO-8601 string
    };
  }

  factory VoicePin.fromMap(Map<String, dynamic> map) {
    return VoicePin(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      memo: map['memo'] ?? '',
      lat: map['lat']?.toDouble() ?? 0.0,
      lon: map['lon']?.toDouble() ?? 0.0,
      created: map['created'] != null
          ? DateTime.parse(map['created'])
          : null, // Parse ISO-8601 string to DateTime
    );
  }

  String toJson() => json.encode(toMap());

  factory VoicePin.fromJson(String source) => VoicePin.fromMap(json.decode(source));

  @override
  String toString() {
    return 'VoicePin(id: $id, name: $name, memo: $memo, lat: $lat, lon: $lon, created: $created)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VoicePin &&
        other.id == id &&
        other.name == name &&
        other.memo == memo &&
        other.lat == lat &&
        other.lon == lon &&
        other.created == created;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        memo.hashCode ^
        lat.hashCode ^
        lon.hashCode ^
        created.hashCode; // no problem if "created" is null.
  }

  int distance(LatLng currentLocation) {
    return calculateDistance(latlng(), currentLocation).toInt();
  }
}
