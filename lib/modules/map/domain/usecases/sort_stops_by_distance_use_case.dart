import '../entity/geo_point_entity.dart';
import '../entity/route_stop_entity.dart';
import 'calculate_geographic_distance_use_case.dart';

/// Use case: orders the route stops by straight-line distance from the
/// user's origin, **nearest first**.
///
/// The farthest stop ends up last: when the route is computed it becomes
/// the final destination, so the trip starts at the closest stop and ends
/// at the most distant one — regardless of the order typed on the form.
/// Between these two extremes the Routes API still optimizes the visiting
/// order for efficiency (`optimizeWaypointOrder`).
class SortStopsByDistanceUseCase {
  SortStopsByDistanceUseCase(this._calculateDistance);

  final CalculateGeographicDistanceUseCase _calculateDistance;

  /// Sorts [stops] by distance to [origin], from nearest to farthest.
  List<RouteStopEntity> execute({
    required GeoPointEntity origin,
    required List<RouteStopEntity> stops,
  }) {
    final sorted = List<RouteStopEntity>.of(stops);
    sorted.sort(
      (a, b) => _calculateDistance.execute(origin, a.location).compareTo(
            _calculateDistance.execute(origin, b.location),
          ),
    );
    return sorted;
  }
}