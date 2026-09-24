import 'package:geolocator/geolocator.dart';

import '../../../../shared/patterns/result.dart';
import '../models/geo_point_model.dart';

class LocationService {
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  Future<bool> canRequestPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission != LocationPermission.deniedForever &&
        permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always;
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<Result<GeoPointModel>> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Result.ok(
        GeoPointModel(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Stream<GeoPointModel> getPositionStream({int distanceFilter = 10}) {
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).map(
      (position) => GeoPointModel(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }
}
