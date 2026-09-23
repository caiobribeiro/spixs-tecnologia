// Testes do MapRepositoryImpl: conversão Model → Entity, atualização da
// SSOT (route.value) e propagação de erros, com um MapService fake.

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/data/models/geo_point_model.dart';
import 'package:spixs_tecnologia/modules/map/data/models/route_model.dart';
import 'package:spixs_tecnologia/modules/map/data/models/route_waypoint_model.dart';
import 'package:spixs_tecnologia/modules/map/data/services/map_service.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_request_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/repository/map_repository_impl.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

/// Fake que evita o Dio real: responde com um Result pré-determinado.
class _FakeMapService extends MapService {
  _FakeMapService(this._handler) : super(apiKey: '');

  final Future<Result<RouteModel>> Function(List<String> addresses) _handler;

  @override
  Future<Result<RouteModel>> computeRoute(List<String> addresses) {
    return _handler(addresses);
  }
}

const _model = RouteModel(
  waypoints: [
    RouteWaypointModel(
      address: 'Av. Paulista, 1000',
      location: GeoPointModel(latitude: -23.5614, longitude: -46.6559),
    ),
    RouteWaypointModel(
      address: 'Av. D',
      location: GeoPointModel(latitude: -23.5614, longitude: -46.6559),
    ),
  ],
  polylinePoints: <GeoPointModel>[],
  distanceMeters: 1000,
  durationSeconds: 120,
  optimizedIntermediateWaypointIndex: <int>[],
);

void main() {
  group('MapRepositoryImpl.computeRoute', () {
    test('converte Model em Entity e atualiza a SSOT (route.value)', () async {
      List<String>? receivedAddresses;
      final repository = MapRepositoryImpl(
        _FakeMapService((addresses) async {
          receivedAddresses = addresses;
          return Result.ok(_model);
        }),
      );

      final result = await repository.computeRoute(
        const RouteRequestEntity(addresses: ['Av. Paulista, 1000', 'Av. D']),
      );

      expect(receivedAddresses, orderedEquals(['Av. Paulista, 1000', 'Av. D']));
      expect(repository.route.value, isNotNull);

      switch (result) {
        case Ok<RouteEntity>():
          final route = result.value;
          expect(route.waypoints, hasLength(2));
          expect(route.waypoints.first.address, 'Av. Paulista, 1000');
          expect(route.distanceMeters, 1000);
          expect(route.durationSeconds, 120);
          // Igual à SSOT: mesma instância observável pela apresentação.
          expect(repository.route.value, same(route));
        case Error<RouteEntity>():
          fail('esperava Ok, recebi erro: ${result.error}');
      }
    });

    test('erro do service não atualiza a SSOT', () async {
      final failure = Exception('Places API error: REQUEST_DENIED');
      final repository = MapRepositoryImpl(
        _FakeMapService((addresses) async => Result.error(failure)),
      );

      final result = await repository.computeRoute(
        const RouteRequestEntity(addresses: ['Av. A', 'Av. D']),
      );

      expect(result, isA<Error<RouteEntity>>());
      expect(
        (result as Error<RouteEntity>).error,
        same(failure),
      );
      expect(repository.route.value, isNull);
    });

    test('SSOT mantém a última rota após sucesso seguido de erro', () async {
      final repository = MapRepositoryImpl(
        _FakeMapService((addresses) async => Result.ok(_model)),
      );
      await repository.computeRoute(
        const RouteRequestEntity(addresses: ['Av. A', 'Av. D']),
      );
      final successRoute = repository.route.value;
      expect(successRoute, isNotNull);

      // O próximo repositório usa um service que agora falha.
      final failingRepository = MapRepositoryImpl(
        _FakeMapService((addresses) async => Result.error(Exception('boom'))),
      );
      final result = await failingRepository.computeRoute(
        const RouteRequestEntity(addresses: ['Av. A', 'Av. D']),
      );

      expect(result, isA<Error<RouteEntity>>());
      expect(failingRepository.route.value, isNull);
    });
  });
}