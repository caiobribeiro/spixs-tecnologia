import 'package:flutter/foundation.dart';

import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/place_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_request_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_waypoint_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/repository/map_repository.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

/// Deterministic [MapRepository] for tests: returns canned entities or a
/// fixed error, never touching the network, and mirrors the SSOT behavior
/// of the real repository ([MapRepositoryImpl.route]).
class FakeMapRepository implements MapRepository {
  FakeMapRepository({
    this.routeResult,
    this.placesResult = const Result.ok(<PlaceEntity>[]),
  });

  /// Resultado do [computeRoute]; quando nulo, retorna uma rota padrão.
  Result<RouteEntity>? routeResult;

  final Result<List<PlaceEntity>> placesResult;

  /// Espelho da SSOT do repositório real.
  @override
  final ValueNotifier<RouteEntity?> route = ValueNotifier<RouteEntity?>(null);

  /// Número de vezes que [computeRoute] foi chamado.
  int computeRouteCalls = 0;

  /// Última requisição recebida, para asserções nos testes.
  RouteRequestEntity? lastRequest;

  @override
  Future<Result<List<PlaceEntity>>> getPlaces() async => placesResult;

  @override
  Future<Result<RouteEntity>> computeRoute(RouteRequestEntity request) async {
    computeRouteCalls++;
    lastRequest = request;

    final result = routeResult ?? const Result.ok(_defaultRoute);
    if (result is Ok<RouteEntity>) {
      route.value = result.value;
    }
    return result;
  }

  /// Rota padrão: origem + destino com um mínimo de campos preenchidos.
  static const RouteEntity _defaultRoute = RouteEntity(
    waypoints: [
      RouteWaypointEntity(
        address: 'Origem',
        location: GeoPointEntity(latitude: -23.5505, longitude: -46.6333),
      ),
      RouteWaypointEntity(
        address: 'Destino',
        location: GeoPointEntity(latitude: -23.5614, longitude: -46.6559),
      ),
    ],
    polylinePoints: <GeoPointEntity>[],
    distanceMeters: 1000,
    durationSeconds: 120,
    optimizedIntermediateWaypointIndex: <int>[],
  );
}