import 'geo_point_entity.dart';
import 'route_waypoint_entity.dart';

class RouteEntity {
  const RouteEntity({
    required this.waypoints,
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.optimizedIntermediateWaypointIndex,
    this.userOrigin,
  });

  final List<RouteWaypointEntity> waypoints;

  final List<GeoPointEntity> polylinePoints;

  final double distanceMeters;

  final int durationSeconds;

  final List<int> optimizedIntermediateWaypointIndex;

  final GeoPointEntity? userOrigin;

  bool get startsFromUserLocation => userOrigin != null;

  GeoPointEntity get origin => waypoints.first.location;

  GeoPointEntity get destination => waypoints.last.location;

  @override
  String toString() =>
      'RouteEntity(waypoints: ${waypoints.length}, '
      'polylinePoints: ${polylinePoints.length}, '
      'distanceMeters: $distanceMeters, durationSeconds: $durationSeconds, '
      'optimizedIntermediateWaypointIndex: '
      '$optimizedIntermediateWaypointIndex, userOrigin: $userOrigin)';
}
