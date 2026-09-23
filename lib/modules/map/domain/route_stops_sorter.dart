import 'entity/geo_point_entity.dart';
import 'entity/route_stop_entity.dart';
import 'geographic_distance.dart';

/// Domain rule that orders the route stops by straight-line distance from
/// the user's origin, **nearest first**.
///
/// The farthest stop ends up last: when the route is computed it becomes
/// the final destination, so the trip starts at the closest stop and ends
/// at the most distant one — regardless of the order typed on the form.
/// Between these two extremes the Routes API still optimizes the visiting
/// order for efficiency (`optimizeWaypointOrder`).
abstract final class RouteStopsSorter {
  /// Sorts [stops] by distance to [origin], from nearest to farthest.
  static List<RouteStopEntity> nearestToFarthestFromOrigin({
    required GeoPointEntity origin,
    required List<RouteStopEntity> stops,
  }) {
    final sorted = List<RouteStopEntity>.of(stops);
    sorted.sort(
      (a, b) => GeographicDistance.meters(origin, a.location).compareTo(
            GeographicDistance.meters(origin, b.location),
          ),
    );
    return sorted;
  }
}