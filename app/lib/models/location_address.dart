import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

class LocationAddress {
  final int? id;
  final String name;
  final String formattedAddress;
  final String street;
  final String number;
  final String zip;
  final String city;
  final String country;
  final double lat;
  final double lon;
  LocationAddress({
    this.id,
    required this.name,
    required this.formattedAddress,
    required this.street,
    required this.number,
    required this.zip,
    required this.city,
    required this.country,
    required this.lat,
    required this.lon,
  });

  LatLng latlng() {
    return LatLng(lat, lon);
  }

  LocationAddress copyWith({
    ValueGetter<int?>? id,
    String? name,
    String? formattedAddress,
    String? street,
    String? number,
    String? zip,
    String? city,
    String? country,
    double? lat,
    double? lon,
  }) {
    return LocationAddress(
      id: id?.call() ?? this.id,
      name: name ?? this.name,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      street: street ?? this.street,
      number: number ?? this.number,
      zip: zip ?? this.zip,
      city: city ?? this.city,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'formattedAddress': formattedAddress,
      'street': street,
      'number': number,
      'zip': zip,
      'city': city,
      'country': country,
      'lat': lat,
      'lon': lon,
    };
  }

  factory LocationAddress.fromMap(Map<String, dynamic> map) {
    return LocationAddress(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      formattedAddress: map['formattedAddress'] ?? '',
      street: map['street'] ?? '',
      number: map['number'] ?? '',
      zip: map['zip'] ?? '',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      lat: map['lat']?.toDouble() ?? 0.0,
      lon: map['lon']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationAddress.fromJson(String source) => LocationAddress.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LocationAddress(id: $id, name: $name, formattedAddress: $formattedAddress, street: $street, number: $number, zip: $zip, city: $city, country: $country, lat: $lat, lon: $lon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LocationAddress &&
        other.id == id &&
        other.name == name &&
        other.formattedAddress == formattedAddress &&
        other.street == street &&
        other.number == number &&
        other.zip == zip &&
        other.city == city &&
        other.country == country &&
        other.lat == lat &&
        other.lon == lon;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        formattedAddress.hashCode ^
        street.hashCode ^
        number.hashCode ^
        zip.hashCode ^
        city.hashCode ^
        country.hashCode ^
        lat.hashCode ^
        lon.hashCode;
  }
}
