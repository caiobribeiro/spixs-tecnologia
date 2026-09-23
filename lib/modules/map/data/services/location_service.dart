import 'package:geolocator/geolocator.dart';

import '../../../../shared/patterns/result.dart';
import '../models/geo_point_model.dart';

/// Map module location data source.
///
/// Thin wrapper around the `geolocator` plugin: exposes the platform
/// capabilities (GPS status, permission checks/requests, opening the
/// system settings) used by the repository to run the location access
/// flow. The orchestration of that flow (order of checks, error mapping)
/// lives in the domain layer (`LocationRepositoryImpl`).
class LocationService {
  /// Whether the device GPS/location service is enabled.
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  /// The current location permission, without prompting the user.
  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  /// Asks the user for the location permission (shows the platform dialog).
  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  /// Whether the platform can still show the permission dialog, i.e. the
  /// user has not selected "never ask again" (`deniedForever`).
  Future<bool> canRequestPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission != LocationPermission.deniedForever &&
        permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always;
  }

  /// Opens the device location settings (GPS on/off screen). Returns
  /// whether the user actually reached the settings app.
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  /// Opens the app settings page where the user can grant permissions.
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  /// The current device position as a [GeoPointModel].
  ///
  /// Returns a [Result] so platform exceptions (e.g. no GPS fix, timeout)
  /// are encapsulated instead of thrown to the caller.
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
}