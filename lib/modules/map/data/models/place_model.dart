import '../../domain/entity/place_entity.dart';
import 'geo_point_model.dart';

/// Data Transfer Object for a point of interest.
class PlaceModel {
  const PlaceModel({
    required this.id,
    required this.name,
    required this.location,
  });

  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    return PlaceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      location: GeoPointModel.fromMap(map['location'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String name;
  final GeoPointModel location;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location.toMap(),
    };
  }

  /// Converts this DTO into the domain entity.
  PlaceEntity toEntity() {
    return PlaceEntity(
      id: id,
      name: name,
      location: location.toEntity(),
    );
  }

  @override
  String toString() => 'PlaceModel($toMap)';
}