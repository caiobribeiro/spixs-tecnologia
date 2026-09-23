class GeoPointEntity {
  const GeoPointEntity({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  String toString() =>
      'GeoPointEntity(latitude: $latitude, longitude: $longitude)';
}
