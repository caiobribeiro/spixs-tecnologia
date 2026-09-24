import 'package:flutter/foundation.dart';

import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/repository/location_repository.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

/// Deterministic [LocationRepository] for tests: exposes a controllable
/// [startPoint] SSOT and a configurable [requestLocationAccess] result,
/// never touching the geolocator plugin.
class FakeLocationRepository implements LocationRepository {
  FakeLocationRepository({GeoPointEntity? startPoint})
      : _startPoint = ValueNotifier<GeoPointEntity?>(startPoint);

  final ValueNotifier<GeoPointEntity?> _startPoint;

  /// Resultado do próximo [requestLocationAccess]; quando `Ok`, o valor
  /// vira o [startPoint] (espelhando o repositório real).
  Result<GeoPointEntity> accessResult =
      Result.ok(_defaultPoint);

  /// Quantas vezes o fluxo de acesso foi executado.
  int accessCalls = 0;

  /// Whether [startLocationUpdates] was called.
  bool locationUpdatesStarted = false;

  /// Localização padrão usada quando nenhuma é configurada no construtor.
  static const GeoPointEntity _defaultPoint =
      GeoPointEntity(latitude: -23.5505, longitude: -46.6333);

  @override
  ValueNotifier<GeoPointEntity?> get startPoint => _startPoint;

  @override
  Future<Result<GeoPointEntity>> requestLocationAccess() async {
    accessCalls++;
    final result = accessResult;
    switch (result) {
      case Ok<GeoPointEntity>():
        _startPoint.value = result.value;
        return result;
      case Error<GeoPointEntity>():
        return result;
    }
  }

  @override
  Future<bool> canRequestPermission() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  void startLocationUpdates() {
    locationUpdatesStarted = true;
  }

  @override
  void stopLocationUpdates() {}
}