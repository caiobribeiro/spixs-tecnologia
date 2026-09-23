import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/patterns/command.dart';
import '../../../../shared/patterns/result.dart';
import '../../domain/entity/geo_point_entity.dart';
import '../../domain/entity/location_access_status.dart';
import '../../domain/entity/place_entity.dart';
import '../../domain/entity/route_entity.dart';
import '../../domain/entity/route_request_entity.dart';
import '../../domain/location_access_failure.dart';
import '../../domain/repository/location_repository.dart';
import '../../domain/repository/map_repository.dart';
import '../../domain/usecases/detect_route_deviation_use_case.dart';
import '../../domain/usecases/find_unvisited_stops_use_case.dart';
import '../../domain/usecases/numbered_marker_use_case.dart';
import '../../domain/usecases/trim_route_path_use_case.dart';

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
///
/// Durante a navegação, cada atualização contínua de GPS é verificada: se o
/// usuário se desviar da rota além do threshold de distância
/// ([DetectRouteDeviationUseCase]), a rota é **recalculada automaticamente**
/// a partir da posição atual considerando apenas as paradas ainda não
/// visitadas ([FindUnvisitedStopsUseCase]), com a nova ordem entre elas
/// reotimizada (regra padrão do repositório) — e a UI é avisada pelo
/// [routeRecalculationCount] para mostrar o banner "Rota recalculada".
class MapViewmodel extends ChangeNotifier {
  MapViewmodel(
    this._repository,
    this._locationRepository,
    this._trimRoutePath,
    this._markerIcons,
    this._detectRouteDeviation,
    this._findUnvisitedStops,
  );

  final MapRepository _repository;
  final LocationRepository _locationRepository;
  final TrimRoutePathUseCase _trimRoutePath;
  final NumberedMarkerUseCase _markerIcons;
  final DetectRouteDeviationUseCase _detectRouteDeviation;
  final FindUnvisitedStopsUseCase _findUnvisitedStops;

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

  /// Indica se a navegação está ativa (botão "Iniciar" pressionado): a
  /// partir daí a câmera acompanha o usuário continuamente e a polyline
  /// passa a mostrar apenas o caminho à frente ([remainingPolylinePoints]).
  final ValueNotifier<bool> navigating = ValueNotifier<bool>(false);

  /// Número de **recálculos automáticos** já executados durante a navegação
  /// (desvio de rota detectado). A UI mostra o banner "Rota recalculada"
  /// sempre que este contador for maior que zero.
  final ValueNotifier<int> routeRecalculationCount = ValueNotifier<int>(0);

  /// Índices das paradas **já visitadas** durante a navegação atual
  /// (relativos às paradas da rota, sem a origem do usuário). Acumulado a
  /// cada atualização de GPS: uma parada que chega ao raio de visita
  /// ([FindUnvisitedStopsUseCase.visitedRadiusMeters]) não volta para o
  /// recálculo, mesmo que o usuário se afaste dela depois.
  final Set<int> _visitedStopIndexes = <int>{};

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
  ValueNotifier<GeoPointEntity?> get startPoint =>
      _locationRepository.startPoint;

  /// Pontos da polyline ainda à frente do usuário, derivados do SSOT da
  /// rota e do SSOT da posição atual.
  ///
  /// Enquanto a navegação não está ativa devolve a geometria completa da
  /// rota; depois de [startNavigation], remove a parte já navegada (até o
  /// ponto da polyline mais próximo da posição do usuário).
  List<GeoPointEntity> get remainingPolylinePoints {
    final route = _repository.route.value;
    if (route == null) {
      return const [];
    }
    final position = startPoint.value;
    if (!navigating.value || position == null) {
      return route.polylinePoints;
    }
    return _trimRoutePath.execute(
      points: route.polylinePoints,
      currentPosition: position,
    );
  }

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

  /// Starts navigation from the user's current location (botão "Iniciar").
  ///
  /// A partir daí o stream de localização continua rastreando a posição
  /// ([startPoint]), o mapa acompanha o usuário continuamente, a polyline
  /// mostra apenas o trecho ainda à frente ([remainingPolylinePoints]) e o
  /// ViewModel passa a verificar desvio de rota em cada atualização de GPS
  /// ([_onPositionChanged]).
  void startNavigation() {
    if (navigating.value) {
      return;
    }
    navigating.value = true;
    _locationRepository.startLocationUpdates();
    _locationRepository.startPoint.addListener(_onPositionChanged);
  }

  /// Generates the numbered marker icon for a waypoint through the
  /// [NumberedMarkerUseCase], which the ViewModel owns (the View never
  /// instantiates use cases directly).
  Future<BitmapDescriptor> numberedMarkerIcon(int number) {
    return _markerIcons.execute(number);
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

  /// Reage às atualizações contínuas de GPS durante a navegação: verifica se
  /// o usuário se desviou da rota (distância até o trecho à frente acima do
  /// threshold) e, quando isso acontece, dispara o recálculo automático.
  void _onPositionChanged() {
    if (!navigating.value) {
      return;
    }
    final route = _repository.route.value;
    final position = startPoint.value;
    if (route == null || position == null) {
      return;
    }

    // Registra as paradas alcançadas (acumulado) para o recálculo
    // considerar apenas o que ainda falta visitar.
    _trackVisitedStops(position);

    // Geometria ainda à frente: usuário mais longe que o threshold dela
    // significa que saiu do caminho planejado.
    final remainingPoints = remainingPolylinePoints;
    if (!_detectRouteDeviation.execute(
      routePoints: remainingPoints,
      position: position,
    )) {
      return;
    }
    unawaited(_recalculateRoute(position));
  }

  /// Marca como visitadas as paradas cuja distância até [position] está
  /// dentro do raio de visita ([FindUnvisitedStopsUseCase]). O registro é
  /// **acumulado**: uma parada visitada não é revista pelo recálculo.
  void _trackVisitedStops(GeoPointEntity position) {
    final route = _repository.route.value;
    if (route == null) {
      return;
    }
    final stopOffset = route.startsFromUserLocation ? 1 : 0;
    final stops = route.waypoints.sublist(stopOffset);
    if (stops.isEmpty) {
      return;
    }

    final unvisited = _findUnvisitedStops.execute(
      waypoints: stops,
      position: position,
    );
    for (var i = 0; i < stops.length; i++) {
      if (!unvisited.contains(stops[i])) {
        _visitedStopIndexes.add(i);
      }
    }
  }

  /// Recalcula a rota a partir da posição atual considerando **apenas as
  /// paradas ainda não visitadas**. A nova ordem entre os pontos restantes
  /// é sempre reotimizada (regra padrão do repositório: ordenação por
  /// distância + `optimizeWaypointOrder` da API) — a ordem original não é
  /// mantida por padrão. Ao concluir com sucesso, incrementa
  /// [routeRecalculationCount] para a UI indicar visualmente o recálculo.
  Future<void> _recalculateRoute(GeoPointEntity position) async {
    if (getRouteCommand.running) {
      return;
    }
    final route = _repository.route.value;
    if (route == null) {
      return;
    }

    // Ignora a origem do usuário (quando a rota começou nela) e as paradas
    // já visitadas: apenas o que falta entra na recalculação, com a posição
    // atual como nova origem.
    final stopOffset = route.startsFromUserLocation ? 1 : 0;
    final stops = route.waypoints.sublist(stopOffset);
    final remainingAddresses = <String>[
      for (var i = 0; i < stops.length; i++)
        if (!_visitedStopIndexes.contains(i)) stops[i].address,
    ];
    if (remainingAddresses.isEmpty) {
      return;
    }

    await getRouteCommand.execute(
      RouteRequestEntity(addresses: remainingAddresses, origin: position),
    );
    if (getRouteCommand.completed) {
      routeRecalculationCount.value++;
      // A nova rota já contém as paradas restantes: o progresso de visita
      // recomeça do zero para ela.
      _visitedStopIndexes.clear();
    }
  }

  @override
  void dispose() {
    _locationRepository.startPoint.removeListener(_onPositionChanged);
    _locationRepository.stopLocationUpdates();
    locationStatus.dispose();
    navigating.dispose();
    routeRecalculationCount.dispose();
    super.dispose();
  }
}
