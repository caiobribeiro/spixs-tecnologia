import 'package:flutter/foundation.dart';

import '../../../../shared/patterns/command.dart';
import '../../../../shared/patterns/result.dart';
import '../domain/entity/geo_point_entity.dart';
import '../domain/entity/location_access_status.dart';
import '../domain/entity/place_entity.dart';
import '../domain/entity/route_entity.dart';
import '../domain/entity/route_request_entity.dart';
import '../domain/location_access_failure.dart';
import '../domain/repository/location_repository.dart';
import '../domain/repository/map_repository.dart';

/// Manages the state and logic of the map screen.
///
/// Exposes [Command]s to perform actions and reads the module SSOT through
/// the [MapRepository] and [LocationRepository] contracts. It never depends
/// on the repository implementations directly.
class MapViewmodel extends ChangeNotifier {
  MapViewmodel(this._repository, this._locationRepository);

  final MapRepository _repository;
  final LocationRepository _locationRepository;

  /// Estado do fluxo de acesso à localização, dirigindo a UI sobre o mapa
  /// (carregando / marcador de partida / avisos de permissão ou GPS).
  final ValueNotifier<LocationAccessStatus> locationStatus =
      ValueNotifier<LocationAccessStatus>(LocationAccessStatus.checking);

  late final initializeLocationCommand = Command0<GeoPointEntity>(
    _requestLocationAccess,
  );

  late final getPlacesCommand = Command0<List<PlaceEntity>>(
    _repository.getPlaces,
  );

  late final getRouteCommand = Command1<RouteEntity, RouteRequestEntity>(
    _repository.computeRoute,
  );

  /// O ponto de partida (localização atual) — SSOT vive no
  /// [LocationRepositoryImpl], acessado pelo contrato [LocationRepository].
  ValueNotifier<GeoPointEntity?> get startPoint => _locationRepository.startPoint;

  /// The latest places loaded by [getPlacesCommand], if any.
  List<PlaceEntity>? get places {
    final result = getPlacesCommand.result;
    if (result is Ok<List<PlaceEntity>>) {
      return result.value;
    }
    return null;
  }

  /// SSOT da rota calculada (vive no [MapRepositoryImpl]).
  ValueNotifier<RouteEntity?> get route => _repository.route;

  /// Executa o fluxo completo de acesso à localização (GPS → permissão →
  /// posição atual). Chamado ao abrir a tela e como retry genérico.
  Future<void> initializeLocation() {
    return initializeLocationCommand.execute();
  }

  /// Ação do aviso "GPS desligado": abre as configurações de localização
  /// do dispositivo e tenta novamente.
  Future<void> enableLocation() async {
    await _locationRepository.openLocationSettings();
    await initializeLocation();
  }

  /// Ação do aviso "permissão negada": re-solicita a permissão; se a
  /// plataforma não puder mais mostrar o diálogo ("não perguntar
  /// novamente"), abre as configurações do app antes de tentar.
  Future<void> grantLocationPermission() async {
    if (await _locationRepository.canRequestPermission()) {
      await initializeLocation();
    } else {
      await _locationRepository.openAppSettings();
      await initializeLocation();
    }
  }

  /// Loads the places shown on the map.
  Future<void> loadPlaces() => getPlacesCommand.execute();

  /// Computes a route for the addresses collected on the form.
  Future<void> loadRoute(RouteRequestEntity request) {
    return getRouteCommand.execute(request);
  }

  Future<Result<GeoPointEntity>> _requestLocationAccess() async {
    locationStatus.value = LocationAccessStatus.checking;
    final result = await _locationRepository.requestLocationAccess();

    switch (result) {
      case Ok<GeoPointEntity>():
        locationStatus.value = LocationAccessStatus.ready;
        return result;
      case Error<GeoPointEntity>():
        final error = result.error;
        if (error is LocationServiceDisabledFailure) {
          locationStatus.value = LocationAccessStatus.serviceDisabled;
        } else if (error is LocationPermissionDeniedFailure) {
          locationStatus.value = LocationAccessStatus.denied;
        } else {
          // Permissão concedida, mas sem posição (ex.: sem fix de GPS):
          // oferece um retry no mesmo fluxo.
          locationStatus.value = LocationAccessStatus.failed;
        }
        return result;
    }
  }
}