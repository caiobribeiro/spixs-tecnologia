import 'geo_point_entity.dart';

class RouteStopEntity {
  const RouteStopEntity({required this.address, required this.location});

  final String address;

  final GeoPointEntity location;

  @override
  String toString() =>
      'RouteStopEntity(address: $address, location: $location)';
}
