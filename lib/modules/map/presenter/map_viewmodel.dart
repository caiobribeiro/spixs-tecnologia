import 'dart:async';

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
///
/// Na entrada do mapa, [initializeRoute] recebe os endereços preenchidos no
/// formulário de rotas; assim que a localização do usuário fica disponível
/// ([startPoint]), a rota é calculada com essa localização como **origem**
/// e os endereços como pontos de parada, na ordem otimizada pela API.
class MapViewmodel extends ChangeNotifier {
  MapViewmodel(this._repository, this._locationRepository);

  final MapRepository _repository;
  final LocationRepository _locationRepository;

  /// Endereços do formulário de rotas (A, B, C...), repassados na navegação
  /// para a tela do mapa e consumidos na entrada.
  List<String>? _addresses;

  /// Garante que a rota com a origem do usuário seja calculada uma única vez
  /// por entrada no mapa, ignorando as atualizações contínuas de GPS.
  bool _routeComputed = false;

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

  /// Prepara o cálculo da rota na entrada do mapa com os [addresses] do
  /// formulário. Se a localização já estiver disponível no SSOT, a rota é
  /// calculada imediatamente; caso contrário, é disparada assim que a
  /// localização chegar ([_requestLocationAccess]).
  Future<void> initializeRoute(List<String> addresses) {
    _addresses = addresses;
    return _computeRouteWithUserOrigin();
  }

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

  /// Calcula a rota otimizada inserindo a localização do usuário como
  /// origem na requisição (origem fixa + endereços do formulário como
  /// paradas, otimizados pela Routes API).
  Future<void> _computeRouteWithUserOrigin() async {
    final origin = startPoint.value;
    final addresses = _addresses;
    if (_routeComputed ||
        origin == null ||
        addresses == null ||
        addresses.isEmpty ||
        getRouteCommand.running) {
      return;
    }
    _routeComputed = true;
    await getRouteCommand.execute(
      RouteRequestEntity(addresses: addresses, origin: origin),
    );
  }

  Future<Result<GeoPointEntity>> _requestLocationAccess() async {
    locationStatus.value = LocationAccessStatus.checking;
    final result = await _locationRepository.requestLocationAccess();

    switch (result) {
      case Ok<GeoPointEntity>():
        locationStatus.value = LocationAccessStatus.ready;
        _locationRepository.startLocationUpdates();
        // Com a localização em mãos, calcula a rota com ela como origem.
        unawaited(_computeRouteWithUserOrigin());
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

  @override
  void dispose() {
    _locationRepository.stopLocationUpdates();
    locationStatus.dispose();
    super.dispose();
  }
}