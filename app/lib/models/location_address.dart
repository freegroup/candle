import 'dart:convert';

class LocationAddress {
  final String street;
  final String number;
  final String zip;
  final String city;
  final String country;
  LocationAddress({
    required this.street,
    required this.number,
    required this.zip,
    required this.city,
    required this.country,
  });

  LocationAddress copyWith({
    String? street,
    String? number,
    String? zip,
    String? city,
    String? country,
  }) {
    return LocationAddress(
      street: street ?? this.street,
      number: number ?? this.number,
      zip: zip ?? this.zip,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'number': number,
      'zip': zip,
      'city': city,
      'country': country,
    };
  }

  factory LocationAddress.fromMap(Map<String, dynamic> map) {
    return LocationAddress(
      street: map['street'] ?? '',
      number: map['number'] ?? '',
      zip: map['zip'] ?? '',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationAddress.fromJson(String source) => LocationAddress.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LocationAddress(street: $street, number: $number, zip: $zip, city: $city, country: $country)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LocationAddress &&
        other.street == street &&
        other.number == number &&
        other.zip == zip &&
        other.city == city &&
        other.country == country;
  }

  @override
  int get hashCode {
    return street.hashCode ^ number.hashCode ^ zip.hashCode ^ city.hashCode ^ country.hashCode;
  }
}
