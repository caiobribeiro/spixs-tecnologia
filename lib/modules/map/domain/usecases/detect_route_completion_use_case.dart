import '../entity/geo_point_entity.dart';
import 'calculate_geographic_distance_use_case.dart';

class DetectRouteCompletionUseCase {
  DetectRouteCompletionUseCase(this._calculateDistance);

  final CalculateGeographicDistanceUseCase _calculateDistance;

  static const double completionRadiusMeters = 50;

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
