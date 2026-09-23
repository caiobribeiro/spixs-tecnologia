// Testes do MapViewmodel: na entrada do mapa, a rota é calculada inserindo
// a localização do usuário como origem na requisição, com os endereços do
// formulário como pontos de parada (e sem recalcular a cada tick de GPS).

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/location_access_status.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_waypoint_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/location_access_failure.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/trim_route_path_use_case.dart';
import 'package:spixs_tecnologia/modules/map/presenter/map_view/map_viewmodel.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/numbered_marker_use_case.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

import 'fakes/fake_location_repository.dart';
import 'fakes/fake_map_repository.dart';

void main() {
  const userLocation = GeoPointEntity(latitude: -23.5505, longitude: -46.6333);

  // Use case reais (stateless), compartilhados entre os testes do viewmodel.
  final trimRoutePath = TrimRoutePathUseCase();
  final markerIconsUseCase = NumberedMarkerUseCase();

  group(
    'MapViewmodel — rota na entrada do mapa com a localização do usuário',
    () {
      test(
        'com localização e endereços, insere o usuário como origem e calcula',
        () async {
          final mapRepository = FakeMapRepository();
          final locationRepository = FakeLocationRepository(
            startPoint: userLocation,
          );
          final viewmodel = MapViewmodel(
            mapRepository,
            locationRepository,
            trimRoutePath,
            markerIconsUseCase,
          );

          await viewmodel.initializeRoute(['Av. A', 'Rua B', 'Rua C']);

          expect(mapRepository.computeRouteCalls, 1);
          final request = mapRepository.lastRequest!;
          expect(request.addresses, orderedEquals(['Av. A', 'Rua B', 'Rua C']));
          // A localização do usuário entra como origem da requisição.
          expect(request.origin, isNotNull);
          expect(request.origin!.latitude, userLocation.latitude);
          expect(request.origin!.longitude, userLocation.longitude);
          expect(request.hasUserOrigin, isTrue);
          // Resultado aplicado na SSOT do módulo `map`.
          expect(mapRepository.route.value, isNotNull);
        },
      );

      test('sem endereços, nenhuma rota é calculada', () async {
        final mapRepository = FakeMapRepository();
        final locationRepository = FakeLocationRepository(
          startPoint: userLocation,
        );
        final viewmodel = MapViewmodel(
          mapRepository,
          locationRepository,
          trimRoutePath,
          markerIconsUseCase,
        );

        await viewmodel.initializeRoute(const []);
        await viewmodel.initializeLocation();

        expect(mapRepository.computeRouteCalls, 0);
        expect(mapRepository.route.value, isNull);
      });

      test('localização chega depois (fluxo normal): calcula a rota ao obter a '
          'posição', () async {
        final mapRepository = FakeMapRepository();
        final locationRepository = FakeLocationRepository();
        final viewmodel = MapViewmodel(
          mapRepository,
          locationRepository,
          trimRoutePath,
          markerIconsUseCase,
        );

        // Entrada do mapa: ainda sem localização no SSOT → não calcula.
        await viewmodel.initializeRoute(['Av. A', 'Rua B', 'Rua C']);
        expect(mapRepository.computeRouteCalls, 0);

        // Acesso à localização concede permissão e obtém a posição.
        locationRepository.accessResult = const Result.ok(userLocation);
        await viewmodel.initializeLocation();

        expect(locationRepository.locationUpdatesStarted, isTrue);
        expect(mapRepository.computeRouteCalls, 1);
        final request = mapRepository.lastRequest!;
        expect(request.addresses, orderedEquals(['Av. A', 'Rua B', 'Rua C']));
        expect(request.origin, isNotNull);
        expect(request.origin!.latitude, userLocation.latitude);
      });

      test(
        'sem localização (permissão negada) não há requisição de rota',
        () async {
          final mapRepository = FakeMapRepository();
          final locationRepository = FakeLocationRepository();
          final viewmodel = MapViewmodel(
            mapRepository,
            locationRepository,
            trimRoutePath,
            markerIconsUseCase,
          );
          locationRepository.accessResult = const Result.error(
            LocationPermissionDeniedFailure(),
          );

          await viewmodel.initializeRoute(['Av. A', 'Rua B', 'Rua C']);
          await viewmodel.initializeLocation();

          expect(viewmodel.locationStatus.value, LocationAccessStatus.denied);
          expect(mapRepository.computeRouteCalls, 0);
        },
      );

      test('não recalcula a rota a cada atualização contínua de GPS', () async {
        final mapRepository = FakeMapRepository();
        final locationRepository = FakeLocationRepository(
          startPoint: userLocation,
        );
        final viewmodel = MapViewmodel(
          mapRepository,
          locationRepository,
          trimRoutePath,
          markerIconsUseCase,
        );

        await viewmodel.initializeRoute(['Av. A', 'Rua B', 'Rua C']);
        expect(mapRepository.computeRouteCalls, 1);

        // Nova leitura de GPS (movimento) não dispara nova requisição: a rota
        // da entrada usa a origem capturada no momento do cálculo.
        locationRepository.startPoint.value = const GeoPointEntity(
          latitude: -23.5614,
          longitude: -46.6559,
        );
        await viewmodel.initializeLocation();
        await Future<void>.delayed(Duration.zero);

        expect(mapRepository.computeRouteCalls, 1);
      });

      test('rota com erro não lança exceção e não preenche a SSOT', () async {
        final mapRepository = FakeMapRepository(
          routeResult: Result.error(Exception('No routes found')),
        );
        final locationRepository = FakeLocationRepository(
          startPoint: userLocation,
        );
        final viewmodel = MapViewmodel(
          mapRepository,
          locationRepository,
          trimRoutePath,
          markerIconsUseCase,
        );

        await viewmodel.initializeRoute(['Av. A', 'Rua B', 'Rua C']);

        expect(mapRepository.computeRouteCalls, 1);
        expect(viewmodel.getRouteCommand.error, isTrue);
        expect(mapRepository.route.value, isNull);
      });

      test('startNavigation ativa a navegação e encurta a polyline para o '
          'caminho à frente', () async {
        const polyline = [
          GeoPointEntity(latitude: -23.5505, longitude: -46.6333),
          GeoPointEntity(latitude: -23.5510, longitude: -46.6340),
          GeoPointEntity(latitude: -23.5520, longitude: -46.6350),
          GeoPointEntity(latitude: -23.5530, longitude: -46.6360),
        ];
        final mapRepository = FakeMapRepository(
          routeResult: Result.ok(
            RouteEntity(
              waypoints: [
                RouteWaypointEntity(address: 'Origem', location: polyline[0]),
                RouteWaypointEntity(address: 'Destino', location: polyline[3]),
              ],
              polylinePoints: polyline,
              distanceMeters: 1000,
              durationSeconds: 120,
              optimizedIntermediateWaypointIndex: const <int>[],
            ),
          ),
        );
        final locationRepository = FakeLocationRepository(
          startPoint: userLocation,
        );
        final viewmodel = MapViewmodel(
          mapRepository,
          locationRepository,
          trimRoutePath,
          markerIconsUseCase,
        );

        await viewmodel.initializeRoute(['Av. A', 'Rua B']);

        // Antes de iniciar: polyline completa.
        expect(viewmodel.remainingPolylinePoints, hasLength(polyline.length));

        viewmodel.startNavigation();

        expect(viewmodel.navigating.value, isTrue);
        // Posição avança para o 3º ponto → restam apenas os pontos à frente.
        locationRepository.startPoint.value = polyline[2];
        expect(viewmodel.remainingPolylinePoints, hasLength(2));
        expect(
          viewmodel.remainingPolylinePoints.first.latitude,
          polyline[2].latitude,
        );
      });

      test('startNavigation é idempotente', () {
        final mapRepository = FakeMapRepository();
        final locationRepository = FakeLocationRepository(
          startPoint: userLocation,
        );
        final viewmodel = MapViewmodel(
          mapRepository,
          locationRepository,
          trimRoutePath,
          markerIconsUseCase,
        );

        viewmodel.startNavigation();
        viewmodel.startNavigation();

        expect(viewmodel.navigating.value, isTrue);
      });
    },
  );
}
