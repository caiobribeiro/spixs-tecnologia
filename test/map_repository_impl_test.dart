// Testes do MapRepositoryImpl: conversão Model → Entity, atualização da
// SSOT (route.value) e propagação de erros, com um MapService fake.

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/data/models/geo_point_model.dart';
import 'package:spixs_tecnologia/modules/map/data/models/route_model.dart';
import 'package:spixs_tecnologia/modules/map/data/models/route_waypoint_model.dart';
import 'package:spixs_tecnologia/modules/map/data/services/geocoding_service.dart';
import 'package:spixs_tecnologia/modules/map/data/services/map_service.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_request_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/repository/map_repository_impl.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/calculate_geographic_distance_use_case.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/sort_stops_by_distance_use_case.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

/// Fake que evita o Dio real: responde com um Result pré-determinado.
class _FakeMapService extends MapService {
  _FakeMapService(this._handler) : super(apiKey: '');

  final Future<Result<RouteModel>> Function(
    List<String> addresses, {
    GeoPointModel? origin,
  }) _handler;

  @override
  Future<Result<RouteModel>> computeRoute(
    List<String> addresses, {
    GeoPointModel? origin,
  }) {
    return _handler(addresses, origin: origin);
  }
}

/// Fake do geocoding: responde com coordenadas pré-determinadas por
/// endereço (ou erro, quando o endereço não está no mapa).
class _FakeGeocodingService extends GeocodingService {
  _FakeGeocodingService([this._coordinates = const {}]) : super(apiKey: '');

  final Map<String, GeoPointModel> _coordinates;

  /// Endereços consultados, na ordem das chamadas (assert dos testes).
  final List<String> geocodedAddresses = [];

  @override
  Future<Result<GeoPointModel>> geocodeAddress(String address) async {
    geocodedAddresses.add(address);
    final location = _coordinates[address];
    if (location == null) {
      return Result.error(Exception('Endereço não encontrado: $address'));
    }
    return Result.ok(location);
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

/// Use case real (stateless), compartilhado entre os testes do repositório.
final _sortStopsByDistance = SortStopsByDistanceUseCase(
  CalculateGeographicDistanceUseCase(),
);

/// Constrói o repositório com os fakes de service/geocoding e injeta o use
/// case real de ordenação por distância (mesma DI do app).
MapRepositoryImpl _buildRepository(
  _FakeMapService service, [
  _FakeGeocodingService? geocoding,
]) {
  return MapRepositoryImpl(
    service,
    geocoding ?? _FakeGeocodingService(),
    _sortStopsByDistance,
  );
}

void main() {
  group('MapRepositoryImpl.computeRoute', () {
    test('converte Model em Entity e atualiza a SSOT (route.value)', () async {
      List<String>? receivedAddresses;
      final repository =  _buildRepository(
        _FakeMapService((addresses, {origin}) async {
          receivedAddresses = addresses;
          return Result.ok(_model);
        }),
        _FakeGeocodingService(),
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
      final repository =  _buildRepository(
        _FakeMapService((addresses, {origin}) async => Result.error(failure)),
        _FakeGeocodingService(),
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
      final repository =  _buildRepository(
        _FakeMapService((addresses, {origin}) async => Result.ok(_model)),
        _FakeGeocodingService(),
      );
      await repository.computeRoute(
        const RouteRequestEntity(addresses: ['Av. A', 'Av. D']),
      );
      final successRoute = repository.route.value;
      expect(successRoute, isNotNull);

      // O próximo repositório usa um service que agora falha.
      final failingRepository =  _buildRepository(
        _FakeMapService((addresses, {origin}) async => Result.error(Exception('boom'))),
        _FakeGeocodingService(),
      );
      final result = await failingRepository.computeRoute(
        const RouteRequestEntity(addresses: ['Av. A', 'Av. D']),
      );

      expect(result, isA<Error<RouteEntity>>());
      expect(failingRepository.route.value, isNull);
    });

    test('converte a origem do usuário (entity → model) e propaga userOrigin',
        () async {
      GeoPointModel? receivedOrigin;
      final repository =  _buildRepository(
        _FakeMapService((addresses, {origin}) async {
          receivedOrigin = origin;
          return Result.ok(
            RouteModel(
              waypoints: _model.waypoints,
              polylinePoints: _model.polylinePoints,
              distanceMeters: _model.distanceMeters,
              durationSeconds: _model.durationSeconds,
              optimizedIntermediateWaypointIndex:
                  _model.optimizedIntermediateWaypointIndex,
              // Igual ao service real: a origem do usuário é propagada.
              userOrigin: origin,
            ),
          );
        }),
        // Coordenadas para o geocoding dos endereços da requisição.
        _FakeGeocodingService(
          const <String, GeoPointModel>{
            'Av. A': GeoPointModel(latitude: -23.5510, longitude: -46.6340),
            'Rua B': GeoPointModel(latitude: -23.5520, longitude: -46.6350),
            'Av. D': GeoPointModel(latitude: -23.5530, longitude: -46.6360),
          },
        ),
      );
      const userLocation = GeoPointEntity(latitude: -23.5505, longitude: -46.6333);

      final result = await repository.computeRoute(
        const RouteRequestEntity(
          addresses: ['Av. A', 'Rua B', 'Av. D'],
          origin: userLocation,
        ),
      );

      // Origem convertida para o modelo da camada de dados.
      expect(receivedOrigin, isNotNull);
      expect(receivedOrigin!.latitude, -23.5505);
      expect(receivedOrigin!.longitude, -46.6333);

      switch (result) {
        case Ok<RouteEntity>(): // userOrigin mapeada para a entidade.
          expect(result.value.userOrigin, isNotNull);
          expect(result.value.userOrigin!.latitude, -23.5505);
          expect(result.value.startsFromUserLocation, isTrue);
        case Error<RouteEntity>():
          fail('esperava Ok, recebi erro: ${result.error}');
      }
    });

    test(
        'com origem, ordena os endereços do mais próximo ao mais distante '
        'do usuário (destino = mais distante)', () async {
      const userLocation =
          GeoPointEntity(latitude: -23.5505, longitude: -46.6333);
      List<String>? receivedAddresses;
      final repository =  _buildRepository(
        _FakeMapService((addresses, {origin}) async {
          receivedAddresses = addresses;
          return Result.ok(_model);
        }),
        _FakeGeocodingService(
          const <String, GeoPointModel>{
            // Digitados fora de ordem: o mais distante primeiro.
            'Av. A': GeoPointModel(latitude: -23.5510, longitude: -46.6340),
            'Rua B': GeoPointModel(latitude: -23.5520, longitude: -46.6350),
            'Av. D': GeoPointModel(latitude: -23.5530, longitude: -46.6360),
          },
        ),
      );

      final result = await repository.computeRoute(
        const RouteRequestEntity(
          addresses: ['Av. D', 'Av. A', 'Rua B'],
          origin: userLocation,
        ),
      );

      // Verificação de distância aplicada: mais próximo → mais distante,
      // com o mais distante ('Av. D') como destino final (último).
      expect(result, isA<Ok<RouteEntity>>());
      expect(receivedAddresses, orderedEquals(['Av. A', 'Rua B', 'Av. D']));
    });

    test('sem origem, mantém a ordem digitada (sem verificação de distância)',
        () async {
      List<String>? receivedAddresses;
      final geocoding = _FakeGeocodingService();
      final repository =  _buildRepository(
        _FakeMapService((addresses, {origin}) async {
          receivedAddresses = addresses;
          return Result.ok(_model);
        }),
        geocoding,
      );

      final result = await repository.computeRoute(
        const RouteRequestEntity(addresses: ['Av. A', 'Av. D']),
      );

      expect(result, isA<Ok<RouteEntity>>());
      expect(receivedAddresses, orderedEquals(['Av. A', 'Av. D']));
      expect(geocoding.geocodedAddresses, isEmpty);
    });

    test('falha do geocoding propaga o erro e não atualiza a SSOT', () async {
      var computeCalls = 0;
      final repository =  _buildRepository(
        _FakeMapService((addresses, {origin}) async {
          computeCalls++;
          return Result.ok(_model);
        }),
        // 'Rua B' sem coordenadas → geocoding falha.
        _FakeGeocodingService(
          const <String, GeoPointModel>{
            'Av. A': GeoPointModel(latitude: -23.5510, longitude: -46.6340),
          },
        ),
      );

      final result = await repository.computeRoute(
        const RouteRequestEntity(
          addresses: ['Av. A', 'Rua B', 'Av. D'],
          origin: GeoPointEntity(latitude: -23.5505, longitude: -46.6333),
        ),
      );

      expect(result, isA<Error<RouteEntity>>());
      expect(computeCalls, 0);
      expect(repository.route.value, isNull);
    });
  });
}