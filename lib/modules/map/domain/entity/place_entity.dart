import 'geo_point_entity.dart';

/// A point of interest shown on the map.
class PlaceEntity {
  const PlaceEntity({
    required this.id,
    required this.name,
    required this.location,
  });

  final String id;
  final String name;

  /// Geographic location of the place.
  final GeoPointEntity location;

  @override
  String toString() => 'PlaceEntity(id: $id, name: $name, location: $location)';
}