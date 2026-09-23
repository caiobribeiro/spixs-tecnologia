import 'geo_point_entity.dart';

/// Value object holding the stops of a route plus the user's current
/// location, used to compute a route through the Google Routes API.
///
/// When [origin] (the user's location) is present, every [addresses] entry
/// is a stop to visit: the last one is the destination and the ones in
/// between are intermediate waypoints — their order can be optimized by the
/// API via `optimizeWaypointOrder`. Without [origin], the first address is
/// the origin and the last is the destination (fallback behavior).
class RouteRequestEntity {
  const RouteRequestEntity({required this.addresses, this.origin});

  /// Addresses in the order they were typed on the form (A, B, C...).
  final List<String> addresses;

  /// Localização atual do usuário, usada como origem da rota. Quando
  /// presente, todos os [addresses] viram pontos de parada (o último é o
  /// destino); quando ausente, o primeiro endereço é a origem.
  final GeoPointEntity? origin;

  /// Whether the route origin is the user's current location instead of an
  /// address from the form.
  bool get hasUserOrigin => origin != null;

  /// Intermediate waypoints (everything between origin and destination).
  List<String> get intermediates {
    if (hasUserOrigin) {
      return addresses.length > 2
          ? addresses.sublist(0, addresses.length - 1)
          : const <String>[];
    }
    return addresses.length > 2
        ? addresses.sublist(1, addresses.length - 1)
        : const <String>[];
  }

  /// Whether the request has at least origin + destination.
  bool get hasAtLeastTwoWaypoints =>
      hasUserOrigin ? addresses.isNotEmpty : addresses.length >= 2;

  @override
  String toString() =>
      'RouteRequestEntity(addresses: $addresses, origin: $origin)';
}