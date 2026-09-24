import '../entity/geo_point_entity.dart';
import 'calculate_geographic_distance_use_case.dart';

class DetectRouteDeviationUseCase {
  DetectRouteDeviationUseCase(this._calculateDistance);

  final CalculateGeographicDistanceUseCase _calculateDistance;

  static const double deviationThresholdMeters = 50;

  bool execute({
    required List<GeoPointEntity> routePoints,
    required GeoPointEntity position,
    double thresholdMeters = deviationThresholdMeters,
  }) {
    if (routePoints.isEmpty) {
      return false;
    }

    var nearestDistance = double.infinity;
    for (final point in routePoints) {
      final distance = _calculateDistance.execute(position, point);
      if (distance < nearestDistance) {
        nearestDistance = distance;
      }
    }
    return nearestDistance > thresholdMeters;
  }
}
