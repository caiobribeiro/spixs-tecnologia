import '../../domain/entity/route_entity.dart';
import 'geo_point_model.dart';
import 'route_waypoint_model.dart';

/// Data Transfer Object for a route computed by the Google Routes API.
class RouteModel {
  const RouteModel({
    required this.waypoints,
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.optimizedIntermediateWaypointIndex,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      waypoints: (map['waypoints'] as List<dynamic>)
          .map(
            (waypoint) =>
                RouteWaypointModel.fromMap(waypoint as Map<String, dynamic>),
          )
          .toList(),
      polylinePoints: (map['polylinePoints'] as List<dynamic>)
          .map((point) => GeoPointModel.fromMap(point as Map<String, dynamic>))
          .toList(),
      distanceMeters: (map['distanceMeters'] as num).toDouble(),
      durationSeconds: (map['durationSeconds'] as num).toInt(),
      optimizedIntermediateWaypointIndex:
          (map['optimizedIntermediateWaypointIndex'] as List<dynamic>)
              .map((index) => (index as num).toInt())
              .toList(),
    );
  }

  /// Stops in the order the route visits them
  /// (origin → intermediate stops → destination).
  final List<RouteWaypointModel> waypoints;

  /// Decoded polyline describing the route geometry.
  final List<GeoPointModel> polylinePoints;

  /// Total distance of the route in meters.
  final double distanceMeters;

  /// Estimated total travel time in seconds.
  final int durationSeconds;

  /// Order the API applied to the intermediate waypoints.
  final List<int> optimizedIntermediateWaypointIndex;

  /// Origin stop, derived from the SSOT (first waypoint).
  GeoPointModel get origin => waypoints.first.location;

  /// Destination stop, derived from the SSOT (last waypoint).
  GeoPointModel get destination => waypoints.last.location;

  Map<String, dynamic> toMap() {
    return {
      'waypoints': waypoints.map((waypoint) => waypoint.toMap()).toList(),
      'polylinePoints': polylinePoints.map((point) => point.toMap()).toList(),
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'optimizedIntermediateWaypointIndex': optimizedIntermediateWaypointIndex,
    };
  }

  /// Converts this DTO into the domain entity.
  RouteEntity toEntity() {
    return RouteEntity(
      waypoints: waypoints.map((waypoint) => waypoint.toEntity()).toList(),
      polylinePoints: polylinePoints.map((point) => point.toEntity()).toList(),
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      optimizedIntermediateWaypointIndex: optimizedIntermediateWaypointIndex,
    );
  }

  @override
  String toString() => 'RouteModel($toMap)';
}