import '../entity/geo_point_entity.dart';
import 'calculate_geographic_distance_use_case.dart';

/// Use case: detects whether the user has deviated from the planned route.
///
/// Compares the user's current position with the route geometry still ahead
/// ([routePoints], normally the trimmed polyline): when the nearest point of
/// that geometry is farther than [deviationThresholdMeters], the user is
/// considered off-route and the navigation must recalculate the route.
///
/// Pure domain rule, consumed by the [MapViewmodel] during navigation on
/// every continuous GPS update.
class DetectRouteDeviationUseCase {
  DetectRouteDeviationUseCase(this._calculateDistance);

  final CalculateGeographicDistanceUseCase _calculateDistance;

  /// Distância (em metros) a partir da qual o usuário é considerado fora da
  /// rota planejada — threshold de desvio.
  static const double deviationThresholdMeters = 150;

  /// Whether [position] is farther than [thresholdMeters] from the nearest
  /// point of [routePoints]. An empty geometry never triggers a deviation
  /// (there is no route ahead to compare against).
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