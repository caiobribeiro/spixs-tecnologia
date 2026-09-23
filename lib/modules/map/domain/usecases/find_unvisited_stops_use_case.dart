import '../entity/geo_point_entity.dart';
import '../entity/route_waypoint_entity.dart';
import 'calculate_geographic_distance_use_case.dart';

/// Use case: filters the route stops that are still to be visited.
///
/// A stop is considered **visited** once the user's position is within
/// [visitedRadiusMeters] of its location. When the user deviates from the
/// route, the recalculation is built from exactly these unvisited stops,
/// with the user's current location as the new origin.
///
/// Pure domain rule, consumed by the [MapViewmodel] during the automatic
/// route recalculation.
class FindUnvisitedStopsUseCase {
  FindUnvisitedStopsUseCase(this._calculateDistance);

  final CalculateGeographicDistanceUseCase _calculateDistance;

  /// Raio (em metros) dentro do qual uma parada é dada como **visitada**:
  /// chegou perto o suficiente para não entrar mais na recalculação.
  static const double visitedRadiusMeters = 50;

  /// The [waypoints] still not visited, keeping their route order.
  List<RouteWaypointEntity> execute({
    required List<RouteWaypointEntity> waypoints,
    required GeoPointEntity position,
    double visitedRadius = visitedRadiusMeters,
  }) {
    return [
      for (final waypoint in waypoints)
        if (_calculateDistance.execute(position, waypoint.location) >
            visitedRadius)
          waypoint,
    ];
  }
}