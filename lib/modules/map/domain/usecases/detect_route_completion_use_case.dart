import '../entity/geo_point_entity.dart';
import 'calculate_geographic_distance_use_case.dart';

/// Use case: detects whether the user has **completed the route** — reached
/// the end of the route polyline (the destination).
///
/// The polyline ends exactly at the route's final point, so closing in on
/// its last point within [completionRadiusMeters] means the whole route was
/// traveled. Pure domain rule, consumed by the [MapViewmodel] on every
/// continuous GPS update during navigation.
class DetectRouteCompletionUseCase {
  DetectRouteCompletionUseCase(this._calculateDistance);

  final CalculateGeographicDistanceUseCase _calculateDistance;

  /// Raio (em metros) dentro do qual a posição do usuário sobre o último
  /// ponto da polyline significa rota concluída.
  static const double completionRadiusMeters = 50;

  /// Whether [position] is within [radiusMeters] of the final point of
  /// [polylinePoints]. An empty polyline is never considered completed.
  bool execute({
    required List<GeoPointEntity> polylinePoints,
    required GeoPointEntity position,
    double radiusMeters = completionRadiusMeters,
  }) {
    if (polylinePoints.isEmpty) {
      return false;
    }
    final destination = polylinePoints.last;
    return _calculateDistance.execute(position, destination) <= radiusMeters;
  }
}