import 'geo_point_entity.dart';

class RouteRequestEntity {
  const RouteRequestEntity({required this.addresses, this.origin});

  final List<String> addresses;

  final GeoPointEntity? origin;

  bool get hasUserOrigin => origin != null;

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

  bool get hasAtLeastTwoWaypoints =>
      hasUserOrigin ? addresses.isNotEmpty : addresses.length >= 2;

  @override
  String toString() =>
      'RouteRequestEntity(addresses: $addresses, origin: $origin)';
}
