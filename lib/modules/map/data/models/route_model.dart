import '../../domain/entity/route_entity.dart';
import 'geo_point_model.dart';

/// Data Transfer Object for a computed route.
class RouteModel {
  const RouteModel({
    required this.origin,
    required this.destination,
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      origin: GeoPointModel.fromMap(map['origin'] as Map<String, dynamic>),
      destination:
          GeoPointModel.fromMap(map['destination'] as Map<String, dynamic>),
      polylinePoints: (map['polylinePoints'] as List<dynamic>)
          .map((point) => GeoPointModel.fromMap(point as Map<String, dynamic>))
          .toList(),
      distanceMeters: (map['distanceMeters'] as num).toDouble(),
      durationSeconds: (map['durationSeconds'] as num).toInt(),
    );
  }

  final GeoPointModel origin;
  final GeoPointModel destination;
  final List<GeoPointModel> polylinePoints;
  final double distanceMeters;
  final int durationSeconds;

  Map<String, dynamic> toMap() {
    return {
      'origin': origin.toMap(),
      'destination': destination.toMap(),
      'polylinePoints': polylinePoints.map((point) => point.toMap()).toList(),
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
    };
  }

  /// Converts this DTO into the domain entity.
  RouteEntity toEntity() {
    return RouteEntity(
      origin: origin.toEntity(),
      destination: destination.toEntity(),
      polylinePoints: polylinePoints.map((point) => point.toEntity()).toList(),
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
  }

  @override
  String toString() => 'RouteModel($toMap)';
}