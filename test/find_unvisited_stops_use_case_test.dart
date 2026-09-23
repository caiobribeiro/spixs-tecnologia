// Testes do FindUnvisitedStopsUseCase: filtra as paradas ainda não
// visitadas — uma parada é visitada quando a posição do usuário está a
// menos de um raio (50m por padrão) da sua localização.

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_waypoint_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/calculate_geographic_distance_use_case.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/find_unvisited_stops_use_case.dart';

void main() {
  final useCase = FindUnvisitedStopsUseCase(
    CalculateGeographicDistanceUseCase(),
  );

  // 0.001° de latitude ≈ 111m.
  const position = GeoPointEntity(latitude: -23.5505, longitude: -46.6333);

  // ~33m do position → dentro do raio de visita (50m).
  const visited = RouteWaypointEntity(
    address: 'Visitada',
    location: GeoPointEntity(latitude: -23.5502, longitude: -46.6333),
  );
  // ~222m do position → ainda não visitada.
  const unvisited = RouteWaypointEntity(
    address: 'Pendente',
    location: GeoPointEntity(latitude: -23.5485, longitude: -46.6333),
  );
  // ~444m do position → também não visitada.
  const unvisitedFar = RouteWaypointEntity(
    address: 'Pendente Distante',
    location: GeoPointEntity(latitude: -23.5465, longitude: -46.6333),
  );

  group('FindUnvisitedStopsUseCase', () {
    test('mantém apenas as paradas fora do raio de visita', () {
      final remaining = useCase.execute(
        waypoints: const [visited, unvisited],
        position: position,
      );
      expect(remaining.map((stop) => stop.address), orderedEquals(['Pendente']));
    });

    test('todas as paradas distantes permanecem na ordem da rota', () {
      final remaining = useCase.execute(
        waypoints: const [unvisited, unvisitedFar],
        position: position,
      );
      expect(
        remaining.map((stop) => stop.address),
        orderedEquals(['Pendente', 'Pendente Distante']),
      );
    });

    test('posição sobre a própria parada a marca como visitada', () {
      final remaining = useCase.execute(
        waypoints: const [unvisited],
        position: unvisited.location,
      );
      expect(remaining, isEmpty);
    });

    test('lista vazia permanece vazia', () {
      final remaining = useCase.execute(
        waypoints: const [],
        position: position,
      );
      expect(remaining, isEmpty);
    });

    test('raio customizado é respeitado', () {
      // ~100m do position.
      const middle = GeoPointEntity(latitude: -23.5496, longitude: -46.6333);
      const stopMiddle = RouteWaypointEntity(address: 'Meio', location: middle);

      final withLargeRadius = useCase.execute(
        waypoints: const [stopMiddle],
        position: position,
        visitedRadius: 200,
      );
      expect(withLargeRadius, isEmpty);

      final withSmallRadius = useCase.execute(
        waypoints: const [stopMiddle],
        position: position,
        visitedRadius: 50,
      );
      expect(withSmallRadius.map((stop) => stop.address), orderedEquals(['Meio']));
    });

    test('não muta a lista de entrada', () {
      const input = [visited, unvisited];
      useCase.execute(waypoints: input, position: position);
      expect(input, hasLength(2));
    });
  });
}