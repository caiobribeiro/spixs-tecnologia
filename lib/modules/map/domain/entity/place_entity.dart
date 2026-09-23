import 'geo_point_entity.dart';

class PlaceEntity {
  const PlaceEntity({
    required this.id,
    required this.name,
    required this.location,
  });

  final String id;
  final String name;

  final GeoPointEntity location;

  @override
  String toString() => 'PlaceEntity(id: $id, name: $name, location: $location)';
}
