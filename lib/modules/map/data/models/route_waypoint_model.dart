import '../../domain/entity/route_waypoint_entity.dart';
import 'geo_point_model.dart';

/// Data Transfer Object for a waypoint of a computed route.
class RouteWaypointModel {
  const RouteWaypointModel({
    required this.address,
    required this.location,
  });

  factory RouteWaypointModel.fromMap(Map<String, dynamic> map) {
    return RouteWaypointModel(
      address: map['address'] as String? ?? '',
      location: GeoPointModel.fromMap(map['location'] as Map<String, dynamic>),
    );
  }

  /// Resolved address of the stop (the one typed/selected on the form).
  final String address;

  /// Geographic location of the stop (markers on the map).
  final GeoPointModel location;

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'location': location.toMap(),
    };
  }

  /// Converts this DTO into the domain entity.
  RouteWaypointEntity toEntity() {
    return RouteWaypointEntity(
      address: address,
      location: location.toEntity(),
    );
  }

  @override
  String toString() => 'RouteWaypointModel($toMap)';
}