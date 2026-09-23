// Testes da regra de distância do módulo do mapa: ordena as paradas da rota
// do endereço mais próximo ao mais distante da localização do usuário.

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/route_stop_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/geographic_distance.dart';
import 'package:spixs_tecnologia/modules/map/domain/route_stops_sorter.dart';

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

  group('GeographicDistance', () {
    test('distância zero entre o mesmo ponto', () {
      expect(GeographicDistance.meters(origin, origin), 0);
    });

    test('é simétrica', () {
      final forward = GeographicDistance.meters(origin, near.location);
      final reverse = GeographicDistance.meters(near.location, origin);
      expect(forward, closeTo(reverse, 0.0001));
    });

    test('ordenação correta dos pontos de teste (near < middle < far)', () {
      final dNear = GeographicDistance.meters(origin, near.location);
      final dMiddle = GeographicDistance.meters(origin, middle.location);
      final dFar = GeographicDistance.meters(origin, far.location);
      expect(dNear, lessThan(dMiddle));
      expect(dMiddle, lessThan(dFar));
    });
  });

  group('RouteStopsSorter.nearestToFarthestFromOrigin', () {
    test('ordena do mais próximo ao mais distante, ignorando a ordem dada', () {
      final sorted = RouteStopsSorter.nearestToFarthestFromOrigin(
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
      final sorted = RouteStopsSorter.nearestToFarthestFromOrigin(
        origin: origin,
        stops: const [],
      );
      expect(sorted, isEmpty);
    });

    test('não muta a lista de entrada', () {
      final input = [far, near, middle];
      RouteStopsSorter.nearestToFarthestFromOrigin(
        origin: origin,
        stops: input,
      );
      expect(input.map((stop) => stop.address), orderedEquals([
        'Distante',
        'Próximo',
        'Meio',
      ]));
    });
  });
}