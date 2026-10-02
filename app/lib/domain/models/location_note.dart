import 'package:candle/domain/models/latlng_provider.dart';
import 'package:candle/utils/geo.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

class LocationNote implements LatLngProvider {
  final int? id;
  final String name;
  final String memo;
  final double lat;
  final double lon;
  final DateTime? created; // Optional timestamp

  LocationNote({
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

  LocationNote copyWith({
    ValueGetter<int?>? id,
    String? name,
    String? memo,
    double? lat,
    double? lon,
    DateTime? created,
  }) {
    return LocationNote(
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

  /// Reads the map written by [toMap], e.g. from a shared `.candle` file.
  factory LocationNote.fromMap(Map<String, dynamic> map) => LocationNote(
        id: (map['id'] as num?)?.toInt(),
        name: map['name'] as String? ?? '',
        memo: map['memo'] as String? ?? '',
        lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
        lon: (map['lon'] as num?)?.toDouble() ?? 0.0,
        created: map['created'] == null ? null : DateTime.tryParse(map['created'] as String),
      );

  @override
  String toString() {
    return 'LocationNote(id: $id, name: $name, memo: $memo, lat: $lat, lon: $lon, created: $created)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LocationNote &&
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
