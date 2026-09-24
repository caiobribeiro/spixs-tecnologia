// Testes do LocationRepositoryImpl: o fluxo de acesso à localização
// (GPS → permissão → posição atual) e a atualização da SSOT (startPoint),
// com um LocationService fake que evita o plugin geolocator.

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:spixs_tecnologia/modules/map/data/models/geo_point_model.dart';
import 'package:spixs_tecnologia/modules/map/data/services/location_service.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/location_access_failure.dart';
import 'package:spixs_tecnologia/modules/map/domain/repository/location_repository_impl.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

/// Fake que evita o geolocator real: controla GPS, permissão e posição.
class _FakeLocationService extends LocationService {
  _FakeLocationService({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.onRequestPermission,
    this.failPosition = false,
  });

  bool serviceEnabled;
  LocationPermission permission;

  /// Resposta do diálogo de permissão; quando nulo, retorna [permission].
  Future<LocationPermission> Function()? onRequestPermission;

  GeoPointModel position = const GeoPointModel(
    latitude: -23.5505,
    longitude: -46.6333,
  );
  bool failPosition;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    return onRequestPermission?.call() ?? permission;
  }

  @override
  Future<Result<GeoPointModel>> getCurrentPosition() async {
    if (failPosition) {
      return Result.error(Exception('Sem fix de GPS.'));
    }
    return Result.ok(position);
  }
}

void main() {
  group('LocationRepositoryImpl — requestLocationAccess', () {
    test('GPS desligado → falha tipada e SSOT permanece vazia', () async {
      final service = _FakeLocationService(serviceEnabled: false);
      final repository = LocationRepositoryImpl(service);

      final result = await repository.requestLocationAccess();

      expect(result, isA<Error<GeoPointEntity>>());
      expect((result as Error<GeoPointEntity>).error,
          isA<LocationServiceDisabledFailure>());
      expect(repository.startPoint.value, isNull);
    });

    test('permissão negada → falha tipada e SSOT permanece vazia', () async {
      final service = _FakeLocationService(
        permission: LocationPermission.denied,
        onRequestPermission: () async => LocationPermission.denied,
      );
      final repository = LocationRepositoryImpl(service);

      final result = await repository.requestLocationAccess();

      expect(result, isA<Error<GeoPointEntity>>());
      expect((result as Error<GeoPointEntity>).error,
          isA<LocationPermissionDeniedFailure>());
      expect(repository.startPoint.value, isNull);
    });

    test('permissão "não perguntar novamente" → falha tipada', () async {
      final service = _FakeLocationService(
        permission: LocationPermission.deniedForever,
      );
      final repository = LocationRepositoryImpl(service);

      final result = await repository.requestLocationAccess();

      expect(result, isA<Error<GeoPointEntity>>());
      expect((result as Error<GeoPointEntity>).error,
          isA<LocationPermissionDeniedFailure>());
    });

    test('permissão negada e concedida depois → posição vira startPoint',
        () async {
      final service = _FakeLocationService(
        permission: LocationPermission.denied,
        onRequestPermission: () async => LocationPermission.whileInUse,
      );
      final repository = LocationRepositoryImpl(service);
      expect(repository.startPoint.value, isNull);

      final result = await repository.requestLocationAccess();

      expect(result, isA<Ok<GeoPointEntity>>());
      expect(repository.startPoint.value?.latitude, -23.5505);
      expect(repository.startPoint.value?.longitude, -46.6333);
    });

    test('permissão já concedida → pula o diálogo e centraliza na posição',
        () async {
      var requestCalled = false;
      final service = _FakeLocationService(
        permission: LocationPermission.whileInUse,
        onRequestPermission: () async {
          requestCalled = true;
          return LocationPermission.whileInUse;
        },
      );
      final repository = LocationRepositoryImpl(service);

      final result = await repository.requestLocationAccess();

      expect(result, isA<Ok<GeoPointEntity>>());
      expect(requestCalled, isFalse);
    });

    test('posição indisponível → erro genérico e SSOT permanece vazia',
        () async {
      final service = _FakeLocationService(failPosition: true);
      final repository = LocationRepositoryImpl(service);

      final result = await repository.requestLocationAccess();

      expect(result, isA<Error<GeoPointEntity>>());
      expect((result as Error<GeoPointEntity>).error,
          isA<Exception>());
      expect(repository.startPoint.value, isNull);
    });
  });
}