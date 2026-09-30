/// A single OSM element returned by the Overpass API.
///
/// Nodes carry their own coordinates, ways and relations only a `center`
/// (requested with `out center;`). Both end up in [lat]/[lon].
final class OverpassElement {
  const OverpassElement({
    required this.type,
    required this.id,
    required this.lat,
    required this.lon,
    required this.tags,
  });

  final String type;
  final int id;
  final double lat;
  final double lon;
  final Map<String, String> tags;

  /// Returns null for elements without a position (e.g. a relation without center).
  static OverpassElement? fromJson(Map<String, Object?> json) {
    final center = json['center'];
    final position = center is Map<String, Object?> ? center : json;
    final lat = position['lat'];
    final lon = position['lon'];
    if (lat is! num || lon is! num) return null;

    final tags = json['tags'];
    return OverpassElement(
      type: json['type'] as String? ?? 'node',
      id: (json['id'] as num?)?.toInt() ?? 0,
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      tags: tags is Map<String, Object?>
          ? {for (final e in tags.entries) e.key: '${e.value}'}
          : const {},
    );
  }
}
