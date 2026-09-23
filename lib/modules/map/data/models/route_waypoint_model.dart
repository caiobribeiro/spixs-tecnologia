import '../../domain/entity/route_waypoint_entity.dart';
import 'geo_point_model.dart';

class RouteWaypointModel {
  const RouteWaypointModel({required this.address, required this.location});

  factory RouteWaypointModel.fromMap(Map<String, dynamic> map) {
    return RouteWaypointModel(
      address: map['address'] as String? ?? '',
      location: GeoPointModel.fromMap(map['location'] as Map<String, dynamic>),
    );
  }

  final String address;

  final GeoPointModel location;

  Map<String, dynamic> toMap() {
    return {'address': address, 'location': location.toMap()};
  }

  RouteWaypointEntity toEntity() {
    return RouteWaypointEntity(address: address, location: location.toEntity());
  }

  @override
  String toString() => 'RouteWaypointModel($toMap)';
}
