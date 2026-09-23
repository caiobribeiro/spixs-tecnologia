/// Value object holding the addresses collected from the address form,
/// used to compute a route through the Google Routes API.
///
/// The first address is the origin, the last is the destination and the
/// ones in between are intermediate waypoints — their order can be
/// optimized by the API via `optimizeWaypointOrder`.
class RouteRequestEntity {
  const RouteRequestEntity({required this.addresses});

  /// Addresses in the order they were typed on the form (A, B, C...).
  final List<String> addresses;

  /// Intermediate waypoints (everything between origin and destination).
  List<String> get intermediates => addresses.length > 2
      ? addresses.sublist(1, addresses.length - 1)
      : const <String>[];

  /// Whether the request has at least origin + destination.
  bool get hasAtLeastTwoWaypoints => addresses.length >= 2;

  @override
  String toString() => 'RouteRequestEntity(addresses: $addresses)';
}