import 'geo_point_entity.dart';

/// An address stop to be visited along a route, with its resolved
/// geographic location.
///
/// Produced by the distance check (geocoding + ordering) that decides the
/// most efficient visit order: from the stop closest to the user's origin
/// to the farthest one.
class RouteStopEntity {
  const RouteStopEntity({
    required this.address,
    required this.location,
  });

  /// Resolved address of the stop (as informed on the route form).
  final String address;

  /// Geographic location of the stop, resolved via geocoding.
  final GeoPointEntity location;

  @override
  String toString() => 'RouteStopEntity(address: $address, location: $location)';
}