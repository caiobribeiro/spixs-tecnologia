import 'geo_point_entity.dart';

/// A stop along a computed route, in the order the route visits it.
///
/// In a multi-waypoint route the origin is `waypoints.first` and the
/// destination `waypoints.last`; when `optimizeWaypointOrder` is used the
/// intermediate stops come reordered by the API.
class RouteWaypointEntity {
  const RouteWaypointEntity({
    required this.address,
    required this.location,
  });

  /// Resolved address of the stop (the one typed/selected on the form).
  final String address;

  /// Geographic location of the stop (markers on the map).
  final GeoPointEntity location;

  @override
  String toString() =>
      'RouteWaypointEntity(address: $address, location: $location)';
}