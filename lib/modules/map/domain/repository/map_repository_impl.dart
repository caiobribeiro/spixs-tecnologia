import 'package:flutter/foundation.dart';

import '../../../../shared/patterns/result.dart';
import '../../data/models/place_model.dart';
import '../../data/models/route_model.dart';
import '../../data/services/map_service.dart';
import '../entity/place_entity.dart';
import '../entity/route_entity.dart';
import '../entity/route_request_entity.dart';
import 'map_repository.dart';

/// Concrete [MapRepository].
///
/// Delegates data access to the [MapService] (data layer), converts the
/// `Model`s returned by the service into domain entities and **owns the
/// SSOT** of the module data ([route]).
class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl(this._service);

  final MapService _service;

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
    final result = await _service.computeRoute(request.addresses);

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
}