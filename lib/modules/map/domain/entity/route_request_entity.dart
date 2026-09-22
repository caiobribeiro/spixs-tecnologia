import 'geo_point_entity.dart';

/// Value object holding the arguments needed to request a route.
///
/// Used so the route action can be executed through a single-argument
/// [Command] (see `shared/patterns/command.dart`).
class RouteRequestEntity {
  const RouteRequestEntity({
    required this.origin,
    required this.destination,
  });

  final GeoPointEntity origin;
  final GeoPointEntity destination;

  @override
  String toString() => 'RouteRequestEntity(origin: $origin, destination: $destination)';
}