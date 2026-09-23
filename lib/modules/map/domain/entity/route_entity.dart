import 'geo_point_entity.dart';
import 'route_waypoint_entity.dart';

/// A route computed by the Google Routes API (`computeRoutes`).
///
/// The single source of truth (SSOT) of the computed route lives in
/// `MapRepositoryImpl`; this entity is the domain representation that the
/// map screen consumes (polyline, waypoints and totals).
class RouteEntity {
  const RouteEntity({
    required this.waypoints,
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.optimizedIntermediateWaypointIndex,
  });

  /// Stops in the order the route visits them
  /// (origin → intermediate stops → destination).
  final List<RouteWaypointEntity> waypoints;

  /// Decoded polyline describing the route geometry.
  final List<GeoPointEntity> polylinePoints;

  /// Total distance of the route in meters.
  final double distanceMeters;

  /// Estimated total travel time in seconds.
  final int durationSeconds;

  /// Order the API applied to the intermediate waypoints, as indexes over
  /// the request `intermediates` (only present with `optimizeWaypointOrder`).
  final List<int> optimizedIntermediateWaypointIndex;

  /// Origin stop, derived from the SSOT (first waypoint).
  GeoPointEntity get origin => waypoints.first.location;

  /// Destination stop, derived from the SSOT (last waypoint).
  GeoPointEntity get destination => waypoints.last.location;

  @override
  String toString() =>
      'RouteEntity(waypoints: ${waypoints.length}, '
      'polylinePoints: ${polylinePoints.length}, '
      'distanceMeters: $distanceMeters, durationSeconds: $durationSeconds, '
      'optimizedIntermediateWaypointIndex: '
      '$optimizedIntermediateWaypointIndex)';
}