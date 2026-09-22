import 'geo_point_entity.dart';

/// A route between an origin and a destination.
class RouteEntity {
  const RouteEntity({
    required this.origin,
    required this.destination,
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final GeoPointEntity origin;
  final GeoPointEntity destination;

  /// Decoded polyline describing the route geometry.
  final List<GeoPointEntity> polylinePoints;

  final double distanceMeters;

  /// Estimated travel time in seconds.
  final int durationSeconds;

  @override
  String toString() =>
      'RouteEntity(origin: $origin, destination: $destination, '
      'polylinePoints: ${polylinePoints.length}, '
      'distanceMeters: $distanceMeters, durationSeconds: $durationSeconds)';
}