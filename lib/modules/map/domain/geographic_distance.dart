import 'dart:math' as math;

import 'entity/geo_point_entity.dart';

/// Haversine straight-line distance between two coordinates, in meters.
///
/// Used by the distance check that orders the route stops from the nearest
/// to the user's origin to the farthest one.
abstract final class GeographicDistance {
  static const double _earthRadiusMeters = 6371000;

  /// Approximate straight-line distance between [a] and [b] in meters.
  static double meters(GeoPointEntity a, GeoPointEntity b) {
    final dLat = _radians(b.latitude - a.latitude);
    final dLng = _radians(b.longitude - a.longitude);
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);

    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    final distance = 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
    return distance.toDouble();
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}