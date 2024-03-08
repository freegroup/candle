import 'package:candle/models/latlng_provider.dart';
import 'package:latlong2/latlong.dart';

// Define the ArticleRef class as before, with improved type handling
class ArticleRef implements LatLngProvider {
  final int pageid;
  final int ns;
  final String title;
  final double lat;
  final double lon;
  final double dist;
  final String primary;

  ArticleRef({
    required this.pageid,
    required this.ns,
    required this.title,
    required this.lat,
    required this.lon,
    required this.dist,
    required this.primary,
  });

  @override
  LatLng latlng() {
    return LatLng(lat, lon);
  }

  factory ArticleRef.fromJson(Map<String, dynamic> json) {
    // Use helper methods to ensure correct types
    return ArticleRef(
      pageid: json['pageid'],
      ns: json['ns'],
      title: json['title'],
      lat: _toDouble(json['lat']),
      lon: _toDouble(json['lon']),
      dist: _toDouble(json['dist']),
      primary: json['primary'] ?? '', // Ensure primary is not null
    );
  }

  // Helper method to safely parse a value as double, handling int to double conversion
  static double _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      throw FormatException('Expected a number but got ${value.runtimeType}');
    }
  }
}
