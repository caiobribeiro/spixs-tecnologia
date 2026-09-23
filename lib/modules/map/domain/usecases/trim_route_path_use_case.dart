import '../entity/geo_point_entity.dart';

class TrimRoutePathUseCase {
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
