import 'dart:math';

/// A job site: a point plus the radius (metres) photos should be taken within.
class SiteLocation {
  const SiteLocation({
    required this.lat,
    required this.lon,
    required this.radius,
  });

  final double lat;
  final double lon;
  final double radius;

  Map<String, Object?> toJson() => {'lat': lat, 'lon': lon, 'r': radius};

  factory SiteLocation.fromJson(Map<String, dynamic> j) => SiteLocation(
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        radius: (j['r'] as num?)?.toDouble() ?? 100,
      );

  /// Great-circle distance in metres (haversine; fine for site checks).
  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earth = 6371000.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLon / 2), 2);
    return 2 * earth * asin(min(1.0, sqrt(a)));
  }

  double distanceTo(double lat2, double lon2) =>
      distanceMeters(lat, lon, lat2, lon2);

  bool contains(double lat2, double lon2) => distanceTo(lat2, lon2) <= radius;
}

/// The nearest project (other than [current]) whose job site contains the point,
/// or null. Used to offer "You are at a job site. Switch project?".
String? suggestProject({
  required Iterable<String> projects,
  required SiteLocation? Function(String name) siteFor,
  required String current,
  required double lat,
  required double lon,
}) {
  // Already on a project whose own site contains you: nothing to suggest.
  if (current.isNotEmpty) {
    final own = siteFor(current);
    if (own != null && own.contains(lat, lon)) return null;
  }
  String? best;
  var bestDistance = double.infinity;
  for (final name in projects) {
    if (name == current) continue;
    final site = siteFor(name);
    if (site == null) continue;
    final d = site.distanceTo(lat, lon);
    if (d <= site.radius && d < bestDistance) {
      best = name;
      bestDistance = d;
    }
  }
  return best;
}
