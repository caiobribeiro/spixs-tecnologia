import '../../domain/entity/route_entity.dart';
import 'geo_point_model.dart';
import 'route_waypoint_model.dart';

class RouteModel {
  const RouteModel({
    required this.waypoints,
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.optimizedIntermediateWaypointIndex,
    this.userOrigin,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    final userOrigin = map['userOrigin'] as Map<String, dynamic>?;
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
      userOrigin: userOrigin == null ? null : GeoPointModel.fromMap(userOrigin),
    );
  }

  final List<RouteWaypointModel> waypoints;

  final List<GeoPointModel> polylinePoints;

  final double distanceMeters;

  final int durationSeconds;

  final List<int> optimizedIntermediateWaypointIndex;

  final GeoPointModel? userOrigin;

  GeoPointModel get origin => waypoints.first.location;

  GeoPointModel get destination => waypoints.last.location;

  Map<String, dynamic> toMap() {
    return {
      'waypoints': waypoints.map((waypoint) => waypoint.toMap()).toList(),
      'polylinePoints': polylinePoints.map((point) => point.toMap()).toList(),
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'optimizedIntermediateWaypointIndex': optimizedIntermediateWaypointIndex,
      'userOrigin': userOrigin?.toMap(),
    };
  }

  RouteEntity toEntity() {
    return RouteEntity(
      waypoints: waypoints.map((waypoint) => waypoint.toEntity()).toList(),
      polylinePoints: polylinePoints.map((point) => point.toEntity()).toList(),
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      optimizedIntermediateWaypointIndex: optimizedIntermediateWaypointIndex,
      userOrigin: userOrigin?.toEntity(),
    );
  }

  @override
  String toString() => 'RouteModel($toMap)';
}
