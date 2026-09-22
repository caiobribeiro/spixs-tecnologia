/// A geographic coordinate (latitude/longitude) used across the map domain.
///
/// Framework-agnostic: the presentation layer converts it into the
/// map widget coordinate type when needed.
class GeoPointEntity {
  const GeoPointEntity({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  String toString() => 'GeoPointEntity(latitude: $latitude, longitude: $longitude)';
}