// Testes dos use cases de distância do módulo do mapa: ordenam as paradas
// da rota do endereço mais próximo ao mais distante da localização do
// usuário.

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_stop_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/calculate_geographic_distance_use_case.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/sort_stops_by_distance_use_case.dart';

void main() {
  const origin = GeoPointEntity(latitude: -23.5505, longitude: -46.6333);

  const near = RouteStopEntity(
    address: 'Próximo',
    location: GeoPointEntity(latitude: -23.5510, longitude: -46.6340),
  );
  const middle = RouteStopEntity(
    address: 'Meio',
    location: GeoPointEntity(latitude: -23.5520, longitude: -46.6350),
  );
  const far = RouteStopEntity(
    address: 'Distante',
    location: GeoPointEntity(latitude: -23.5530, longitude: -46.6360),
  );

  group('CalculateGeographicDistanceUseCase', () {
    final useCase = CalculateGeographicDistanceUseCase();

    test('distância zero entre o mesmo ponto', () {
      expect(useCase.execute(origin, origin), 0);
    });

    test('é simétrica', () {
      final forward = useCase.execute(origin, near.location);
      final reverse = useCase.execute(near.location, origin);
      expect(forward, closeTo(reverse, 0.0001));
    });

    test('ordenação correta dos pontos de teste (near < middle < far)', () {
      final dNear = useCase.execute(origin, near.location);
      final dMiddle = useCase.execute(origin, middle.location);
      final dFar = useCase.execute(origin, far.location);
      expect(dNear, lessThan(dMiddle));
      expect(dMiddle, lessThan(dFar));
    });
  });

  group('SortStopsByDistanceUseCase', () {
    final useCase =
        SortStopsByDistanceUseCase(CalculateGeographicDistanceUseCase());

    test('ordena do mais próximo ao mais distante, ignorando a ordem dada',
        () {
      final sorted = useCase.execute(
        origin: origin,
        stops: [far, near, middle],
      );
      expect(sorted.map((stop) => stop.address), orderedEquals([
        'Próximo',
        'Meio',
        'Distante',
      ]));
    });

    test('lista vazia permanece vazia', () {
      final sorted = useCase.execute(
        origin: origin,
        stops: const [],
      );
      expect(sorted, isEmpty);
    });

    test('não muta a lista de entrada', () {
      final input = [far, near, middle];
      useCase.execute(origin: origin, stops: input);
      expect(input.map((stop) => stop.address), orderedEquals([
        'Distante',
        'Próximo',
        'Meio',
      ]));
    });
  });
}