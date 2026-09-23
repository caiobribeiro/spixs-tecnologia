// Testes do MapViewmodel: na entrada do mapa, a rota é calculada inserindo
// a localização do usuário como origem na requisição, com os endereços do
// formulário como pontos de parada (e sem recalcular a cada tick de GPS).

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/location_access_status.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_waypoint_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/location_access_failure.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/calculate_geographic_distance_use_case.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/detect_route_completion_use_case.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/detect_route_deviation_use_case.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/find_unvisited_stops_use_case.dart';
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
  final detectRouteDeviation = DetectRouteDeviationUseCase(
    CalculateGeographicDistanceUseCase(),
  );
  final findUnvisitedStops = FindUnvisitedStopsUseCase(
    CalculateGeographicDistanceUseCase(),
  );
  final detectRouteCompletion = DetectRouteCompletionUseCase(
    CalculateGeographicDistanceUseCase(),
  );

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
            detectRouteDeviation,
            findUnvisitedStops,
            detectRouteCompletion,
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
          detectRouteDeviation,
          findUnvisitedStops,
          detectRouteCompletion,
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
          detectRouteDeviation,
          findUnvisitedStops,
          detectRouteCompletion,
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
            detectRouteDeviation,
            findUnvisitedStops,
            detectRouteCompletion,
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
          detectRouteDeviation,
          findUnvisitedStops,
          detectRouteCompletion,
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
          detectRouteDeviation,
          findUnvisitedStops,
          detectRouteCompletion,
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
          detectRouteDeviation,
          findUnvisitedStops,
          detectRouteCompletion,
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
          detectRouteDeviation,
          findUnvisitedStops,
          detectRouteCompletion,
        );

        viewmodel.startNavigation();
        viewmodel.startNavigation();

        expect(viewmodel.navigating.value, isTrue);
      });
    },
  );

  group('MapViewmodel — desvio de rota e recálculo automático', () {
    // Rota: origem do usuário + 2 paradas. A polyline acompanha as paradas
    // para o trim/desvio terem geometria para comparar.
    const routeOrigin =
        GeoPointEntity(latitude: -23.5505, longitude: -46.6333);
    const stopA =
        GeoPointEntity(latitude: -23.5512, longitude: -46.6342);
    const stopB =
        GeoPointEntity(latitude: -23.5520, longitude: -46.6350);
    // ~220m ao norte da rota: além do threshold de desvio (150m).
    const offRoute =
        GeoPointEntity(latitude: -23.5485, longitude: -46.6333);

    RouteEntity routeWithStops() => RouteEntity(
          waypoints: [
            const RouteWaypointEntity(address: 'Sua localização', location: routeOrigin),
            const RouteWaypointEntity(address: 'Parada A', location: stopA),
            const RouteWaypointEntity(address: 'Parada B', location: stopB),
          ],
          polylinePoints: const [routeOrigin, stopA, stopB],
          distanceMeters: 2400,
          durationSeconds: 300,
          optimizedIntermediateWaypointIndex: const <int>[],
          userOrigin: routeOrigin,
        );

    test('desvio além do threshold recalcula com os pontos restantes', () async {
      final mapRepository = FakeMapRepository(
        routeResult: Result.ok(routeWithStops()),
      );
      final locationRepository = FakeLocationRepository(
        startPoint: routeOrigin,
      );
      final viewmodel = MapViewmodel(
        mapRepository,
        locationRepository,
        trimRoutePath,
        markerIconsUseCase,
        detectRouteDeviation,
        findUnvisitedStops,
        detectRouteCompletion,
      );

      await viewmodel.initializeRoute(['Parada A', 'Parada B']);
      expect(mapRepository.computeRouteCalls, 1);

      viewmodel.startNavigation();
      // Usuário se desvia da rota (posição além do threshold).
      locationRepository.startPoint.value = offRoute;
      await Future<void>.delayed(Duration.zero);

      // Recálculo automático disparado: nova requisição com a posição atual
      // como origem e as paradas ainda não visitadas.
      expect(mapRepository.computeRouteCalls, 2);
      final request = mapRepository.lastRequest!;
      expect(request.addresses, orderedEquals(['Parada A', 'Parada B']));
      expect(request.origin!.latitude, offRoute.latitude);
      expect(request.origin!.longitude, offRoute.longitude);
      // Indicação visual: contador de recálculos incrementado.
      expect(viewmodel.routeRecalculationCount.value, 1);
    });

    test('posição sobre a rota não dispara recálculo', () async {
      final mapRepository = FakeMapRepository(
        routeResult: Result.ok(routeWithStops()),
      );
      final locationRepository = FakeLocationRepository(
        startPoint: routeOrigin,
      );
      final viewmodel = MapViewmodel(
        mapRepository,
        locationRepository,
        trimRoutePath,
        markerIconsUseCase,
        detectRouteDeviation,
        findUnvisitedStops,
        detectRouteCompletion,
      );

      await viewmodel.initializeRoute(['Parada A', 'Parada B']);
      viewmodel.startNavigation();

      // Avança pela rota (sobre a própria polyline): sem desvio, sem recálculo.
      locationRepository.startPoint.value = stopA;
      await Future<void>.delayed(Duration.zero);

      expect(mapRepository.computeRouteCalls, 1);
      expect(viewmodel.routeRecalculationCount.value, 0);
    });

    test('recálculo ignora paradas já visitadas', () async {
      final mapRepository = FakeMapRepository(
        routeResult: Result.ok(routeWithStops()),
      );
      final locationRepository = FakeLocationRepository(
        startPoint: routeOrigin,
      );
      final viewmodel = MapViewmodel(
        mapRepository,
        locationRepository,
        trimRoutePath,
        markerIconsUseCase,
        detectRouteDeviation,
        findUnvisitedStops,
        detectRouteCompletion,
      );

      await viewmodel.initializeRoute(['Parada A', 'Parada B']);
      viewmodel.startNavigation();

      // Desvio em cima do ponto A: A já foi visitada → só B entra no recálculo.
      locationRepository.startPoint.value = stopA;
      await Future<void>.delayed(Duration.zero);
      expect(mapRepository.computeRouteCalls, 1);

      locationRepository.startPoint.value = offRoute;
      await Future<void>.delayed(Duration.zero);

      expect(mapRepository.computeRouteCalls, 2);
      final request = mapRepository.lastRequest!;
      expect(request.addresses, orderedEquals(['Parada B']));
      expect(request.origin, isNotNull);
      expect(viewmodel.routeRecalculationCount.value, 1);
    });

    test('sem navegação ativa, mudar de posição não recalcula', () async {
      final mapRepository = FakeMapRepository(
        routeResult: Result.ok(routeWithStops()),
      );
      final locationRepository = FakeLocationRepository(
        startPoint: routeOrigin,
      );
      final viewmodel = MapViewmodel(
        mapRepository,
        locationRepository,
        trimRoutePath,
        markerIconsUseCase,
        detectRouteDeviation,
        findUnvisitedStops,
        detectRouteCompletion,
      );

      await viewmodel.initializeRoute(['Parada A', 'Parada B']);

      // Posição muda (GPS), mas a navegação nunca começou.
      locationRepository.startPoint.value = offRoute;
      await Future<void>.delayed(Duration.zero);

      expect(mapRepository.computeRouteCalls, 1);
      expect(viewmodel.routeRecalculationCount.value, 0);
    });
  });

  group('MapViewmodel — fim do trajeto (fim da polyline)', () {
    const routeOrigin =
        GeoPointEntity(latitude: -23.5505, longitude: -46.6333);
    const stopA =
        GeoPointEntity(latitude: -23.5512, longitude: -46.6342);
    const stopB =
        GeoPointEntity(latitude: -23.5520, longitude: -46.6350);
    // ~220m ao norte da rota: além do threshold de desvio (150m).
    const offRoute =
        GeoPointEntity(latitude: -23.5485, longitude: -46.6333);

    RouteEntity routeWithStops() => RouteEntity(
          waypoints: [
            const RouteWaypointEntity(address: 'Sua localização', location: routeOrigin),
            const RouteWaypointEntity(address: 'Parada A', location: stopA),
            const RouteWaypointEntity(address: 'Parada B', location: stopB),
          ],
          // A polyline termina exatamente no destino final (último ponto).
          polylinePoints: const [routeOrigin, stopA, stopB],
          distanceMeters: 2400,
          durationSeconds: 300,
          optimizedIntermediateWaypointIndex: const <int>[],
          userOrigin: routeOrigin,
        );

    MapViewmodel buildViewmodel(
      FakeMapRepository mapRepository,
      FakeLocationRepository locationRepository,
    ) {
      return MapViewmodel(
        mapRepository,
        locationRepository,
        trimRoutePath,
        markerIconsUseCase,
        detectRouteDeviation,
        findUnvisitedStops,
        detectRouteCompletion,
      );
    }

    test('chegar ao fim da polyline marca o trajeto como concluído', () async {
      final mapRepository = FakeMapRepository(
        routeResult: Result.ok(routeWithStops()),
      );
      final locationRepository = FakeLocationRepository(
        startPoint: routeOrigin,
      );
      final viewmodel = buildViewmodel(mapRepository, locationRepository);

      await viewmodel.initializeRoute(['Parada A', 'Parada B']);
      viewmodel.startNavigation();
      expect(viewmodel.routeFinished.value, isFalse);

      // No meio do trajeto: ainda não concluído.
      locationRepository.startPoint.value = stopA;
      await Future<void>.delayed(Duration.zero);
      expect(viewmodel.routeFinished.value, isFalse);

      // No fim da polyline (último ponto): concluído.
      locationRepository.startPoint.value = stopB;
      await Future<void>.delayed(Duration.zero);
      expect(viewmodel.routeFinished.value, isTrue);
      // Concluído sem requisições extras além da rota inicial.
      expect(mapRepository.computeRouteCalls, 1);
    });

    test('conclui ao chegar perto do fim da polyline, mesmo sem visitar ' 
        'todas as paradas formalmente', () async {
      final mapRepository = FakeMapRepository(
        routeResult: Result.ok(routeWithStops()),
      );
      final locationRepository = FakeLocationRepository(
        startPoint: routeOrigin,
      );
      final viewmodel = buildViewmodel(mapRepository, locationRepository);

      await viewmodel.initializeRoute(['Parada A', 'Parada B']);
      viewmodel.startNavigation();

      // ~30m antes do fim da polyline (dentro do raio de conclusão de 50m),
      // sem nunca ter chegado perto da parada B: o fim da polyline decide.
      const nearDestination =
          GeoPointEntity(latitude: -23.5517, longitude: -46.6350);
      locationRepository.startPoint.value = nearDestination;
      await Future<void>.delayed(Duration.zero);

      expect(viewmodel.routeFinished.value, isTrue);
    });

    test('depois de concluído, desvio não dispara recálculo', () async {
      final mapRepository = FakeMapRepository(
        routeResult: Result.ok(routeWithStops()),
      );
      final locationRepository = FakeLocationRepository(
        startPoint: routeOrigin,
      );
      final viewmodel = buildViewmodel(mapRepository, locationRepository);

      await viewmodel.initializeRoute(['Parada A', 'Parada B']);
      viewmodel.startNavigation();
      locationRepository.startPoint.value = stopB;
      await Future<void>.delayed(Duration.zero);
      expect(viewmodel.routeFinished.value, isTrue);

      // Mesmo longe da rota (desvio), o trajeto concluído permanece: sem
      // recálculo e o contador continua zerado.
      locationRepository.startPoint.value = offRoute;
      await Future<void>.delayed(Duration.zero);

      expect(mapRepository.computeRouteCalls, 1);
      expect(viewmodel.routeRecalculationCount.value, 0);
    });
  });
}
