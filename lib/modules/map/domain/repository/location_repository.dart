import 'package:flutter/foundation.dart';

import '../../../../shared/patterns/result.dart';
import '../entity/geo_point_entity.dart';

abstract interface class LocationRepository {
  ValueNotifier<GeoPointEntity?> get startPoint;

  Future<Result<GeoPointEntity>> requestLocationAccess();

  Future<bool> canRequestPermission();

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();

  void startLocationUpdates();

  void stopLocationUpdates();
}
