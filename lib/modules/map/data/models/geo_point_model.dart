import '../../domain/entity/geo_point_entity.dart';

class GeoPointModel {
  const GeoPointModel({required this.latitude, required this.longitude});

  factory GeoPointModel.fromMap(Map<String, dynamic> map) {
    return GeoPointModel(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  final double latitude;
  final double longitude;

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  GeoPointEntity toEntity() {
    return GeoPointEntity(latitude: latitude, longitude: longitude);
  }

  @override
  String toString() => 'GeoPointModel($toMap)';
}
