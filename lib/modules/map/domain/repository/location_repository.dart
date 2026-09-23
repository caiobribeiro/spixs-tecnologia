import 'package:flutter/foundation.dart';

import '../../../../shared/patterns/result.dart';
import '../entity/geo_point_entity.dart';

/// Contract for accessing the device location on the map screen.
///
/// The concrete implementation (`LocationRepositoryImpl`) owns the
/// **single source of truth (SSOT)** of the start point: [startPoint]
/// exposes the current location (route origin), observable by the
/// presentation layer.
abstract interface class LocationRepository {
  /// SSOT do ponto de partida (localização atual do usuário), ou `null`
  /// enquanto a localização ainda não foi obtida.
  ValueNotifier<GeoPointEntity?> get startPoint;

  /// Runs the full location access flow in order:
  ///
  /// 1. checks whether the GPS/location service is enabled;
  /// 2. checks/requests the location permission;
  /// 3. fetches the current position and updates [startPoint].
  ///
  /// Failure causes are returned as typed [LocationAccessFailure]s so the
  /// presentation layer can offer the right recovery action.
  Future<Result<GeoPointEntity>> requestLocationAccess();

  /// Whether the platform can still show the permission dialog, i.e. the
  /// user has not selected "never ask again" (`deniedForever`).
  Future<bool> canRequestPermission();

  /// Opens the device settings so the user can turn GPS on (the return
  /// value indicates whether the settings screen was actually opened).
  Future<bool> openLocationSettings();

  /// Opens the app settings page where the user can grant permissions.
  Future<bool> openAppSettings();
}