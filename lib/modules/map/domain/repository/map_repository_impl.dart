import 'package:flutter/foundation.dart';

import '../../../../shared/patterns/result.dart';
import '../../data/models/geo_point_model.dart';
import '../../data/models/place_model.dart';
import '../../data/models/route_model.dart';
import '../../data/services/geocoding_service.dart';
import '../../data/services/map_service.dart';
import '../entity/geo_point_entity.dart';
import '../entity/place_entity.dart';
import '../entity/route_entity.dart';
import '../entity/route_request_entity.dart';
import '../entity/route_stop_entity.dart';
import '../usecases/sort_stops_by_distance_use_case.dart';
import 'map_repository.dart';

/// Concrete [MapRepository].
///
/// Delegates data access to the [MapService] (data layer), converts the
/// `Model`s returned by the service into domain entities and **owns the
/// SSOT** of the module data ([route]).
class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl(
    this._service,
    this._geocodingService,
    this._sortStopsByDistance,
  );

  final MapService _service;
  final GeocodingService _geocodingService;
  final SortStopsByDistanceUseCase _sortStopsByDistance;

  /// SSOT da rota calculada — única fonte da verdade para a tela do mapa.
  ///
  /// Nenhuma outra camada guarda uma cópia própria: a apresentação observa
  /// este [ValueNotifier] através do contrato [MapRepository.route].
  final ValueNotifier<RouteEntity?> _route = ValueNotifier<RouteEntity?>(null);

  @override
  ValueNotifier<RouteEntity?> get route => _route;

  @override
  Future<Result<List<PlaceEntity>>> getPlaces() async {
    final result = await _service.getPlaces();

    switch (result) {
      case Ok<List<PlaceModel>>():
        final value = result.value;
        return Result.ok(value.map((model) => model.toEntity()).toList());
      case Error<List<PlaceModel>>():
        final value = result;
        return Result.error(value.error);
    }
  }

  @override
  Future<Result<RouteEntity>> computeRoute(RouteRequestEntity request) async {
    final origin = request.origin;
    if (origin == null) {
      // Sem a localização do usuário não há ponto de referência para a
      // verificação de distância: segue o fluxo atual (a API otimiza os
      // waypoints intermediários).
      return _compute(request.addresses, origin: null);
    }

    // Verificação de distância: resolve as coordenadas de cada endereço e
    // ordena do **mais próximo ao mais distante** do usuário. O mais
    // distante vira o último endereço da requisição, i.e. o destino final
    // da rota — a ordem digitada deixa de definir a rota.
    final stopsResult =
        await _resolveStopsOrderedByDistance(request.addresses, origin);
    switch (stopsResult) {
      case Ok<List<RouteStopEntity>>():
        final orderedAddresses =
            stopsResult.value.map((stop) => stop.address).toList();
        return _compute(
          orderedAddresses,
          origin: GeoPointModel(
            latitude: origin.latitude,
            longitude: origin.longitude,
          ),
        );
      case Error<List<RouteStopEntity>>():
        final value = stopsResult;
        return Result.error(value.error);
    }
  }

  /// Delegates to the data layer ([MapService.computeRoute]) converting the
  /// `Model` returned into the domain entity. Only the SSOT is updated
  /// after the API succeeds.
  Future<Result<RouteEntity>> _compute(
    List<String> addresses, {
    GeoPointModel? origin,
  }) async {
    final result = await _service.computeRoute(addresses, origin: origin);

    switch (result) {
      case Ok<RouteModel>():
        final value = result.value.toEntity();
        // Só a SSOT é atualizada após o sucesso da API.
        _route.value = value;
        return Result.ok(value);
      case Error<RouteModel>():
        final value = result;
        return Result.error(value.error);
    }
  }

  /// Geocoda cada endereço, converte Model → Entity e retorna as paradas
  /// ordenadas pela distância (em linha reta) até [origin]: do mais
  /// próximo ao mais distante. Falha com o primeiro erro de geocoding.
  Future<Result<List<RouteStopEntity>>> _resolveStopsOrderedByDistance(
    List<String> addresses,
    GeoPointEntity origin,
  ) async {
    if (addresses.isEmpty) {
      return const Result.ok([]);
    }

    final geocodeResults = await Future.wait<Result<GeoPointModel>>(
      [
        for (final address in addresses) _geocodingService.geocodeAddress(address),
      ],
    );

    final stops = <RouteStopEntity>[];
    for (var i = 0; i < geocodeResults.length; i++) {
      final geocodeResult = geocodeResults[i];
      switch (geocodeResult) {
        case Ok<GeoPointModel>():
          stops.add(
            RouteStopEntity(
              address: addresses[i],
              location: geocodeResult.value.toEntity(),
            ),
          );
        case Error<GeoPointModel>():
          final value = geocodeResult;
          return Result.error(value.error);
      }
    }

    return Result.ok(
      _sortStopsByDistance.execute(origin: origin, stops: stops),
    );
  }
}