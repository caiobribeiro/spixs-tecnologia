import '../entity/geo_point_entity.dart';
import '../entity/route_waypoint_entity.dart';
import 'calculate_geographic_distance_use_case.dart';

class FindUnvisitedStopsUseCase {
  FindUnvisitedStopsUseCase(this._calculateDistance);

  final CalculateGeographicDistanceUseCase _calculateDistance;

  static const double visitedRadiusMeters = 50;

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
