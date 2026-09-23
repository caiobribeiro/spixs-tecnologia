import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../shared/patterns/result.dart';
import '../../data/models/geo_point_model.dart';
import '../../data/services/location_service.dart';
import '../entity/geo_point_entity.dart';
import '../location_access_failure.dart';
import 'location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._service);

  final LocationService _service;

  final ValueNotifier<GeoPointEntity?> _startPoint =
      ValueNotifier<GeoPointEntity?>(null);

  StreamSubscription<GeoPointModel>? _positionSubscription;

  @override
  ValueNotifier<GeoPointEntity?> get startPoint => _startPoint;

  @override
  Future<Result<GeoPointEntity>> requestLocationAccess() async {
    if (!await _service.isLocationServiceEnabled()) {
      return const Result.error(LocationServiceDisabledFailure());
    }

    var permission = await _service.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _service.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const Result.error(LocationPermissionDeniedFailure());
    }

    final result = await _service.getCurrentPosition();
    switch (result) {
      case Ok<GeoPointModel>():
        final value = result.value.toEntity();
        _startPoint.value = value;
        return Result.ok(value);
      case Error<GeoPointModel>():
        final value = result;
        return Result.error(value.error);
    }
  }

  @override
  Future<bool> canRequestPermission() {
    return _service.canRequestPermission();
  }

  @override
  Future<bool> openLocationSettings() {
    return _service.openLocationSettings();
  }

  @override
  Future<bool> openAppSettings() {
    return _service.openAppSettings();
  }

  @override
  void startLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = _service.getPositionStream().listen((model) {
      _startPoint.value = model.toEntity();
    });
  }

  @override
  void stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
