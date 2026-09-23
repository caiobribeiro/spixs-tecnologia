import '../entity/geo_point_entity.dart';

/// Use case: trims a route polyline to the portion still ahead of the
/// user.
///
/// Given the full decoded polyline of the computed route and the user's
/// current location, returns the geometry that still needs to be traveled —
/// the stretch already navigated is dropped so the map keeps drawing only
/// the path ahead.
class TrimRoutePathUseCase {
  /// The sublist of [points] starting at the polyline point nearest to
  /// [currentPosition]. When [points] is empty, returns an empty list.
  List<GeoPointEntity> execute({
    required List<GeoPointEntity> points,
    required GeoPointEntity currentPosition,
  }) {
    if (points.isEmpty) {
      return const [];
    }

    var nearestIndex = 0;
    var nearestSquaredDistance = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final squaredDistance = _squaredDistance(points[i], currentPosition);
      if (squaredDistance < nearestSquaredDistance) {
        nearestSquaredDistance = squaredDistance;
        nearestIndex = i;
      }
    }

    if (nearestIndex == 0) {
      return points;
    }
    return points.sublist(nearestIndex);
  }

  static double _squaredDistance(GeoPointEntity a, GeoPointEntity b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
  }
}