import 'geo_point_entity.dart';

class RouteWaypointEntity {
  const RouteWaypointEntity({required this.address, required this.location});

  final String address;

  final GeoPointEntity location;

  @override
  String toString() =>
      'RouteWaypointEntity(address: $address, location: $location)';
}
