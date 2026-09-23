// Testes do RoutePathTrimmer: regra de domínio que remove da polyline a
// parte já navegada, mantendo apenas o caminho à frente do usuário.

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/route_path_trimmer.dart';

void main() {
  group('RoutePathTrimmer', () {
    const points = [
      GeoPointEntity(latitude: -23.5505, longitude: -46.6333),
      GeoPointEntity(latitude: -23.5510, longitude: -46.6340),
      GeoPointEntity(latitude: -23.5520, longitude: -46.6350),
      GeoPointEntity(latitude: -23.5530, longitude: -46.6360),
    ];

    test('polyline vazia retorna lista vazia', () {
      expect(
        RoutePathTrimmer.remaining(points: const [], current: points.first),
        isEmpty,
      );
    });

    test('usuário na origem mantém a rota completa', () {
      final remaining = RoutePathTrimmer.remaining(
        points: points,
        current: points.first,
      );
      expect(remaining, hasLength(points.length));
      expect(remaining.first.latitude, points.first.latitude);
      expect(remaining.last.latitude, points.last.latitude);
    });

    test('remove a parte já navegada a partir do ponto mais próximo', () {
      // Usuário no 3º ponto da polyline → restam o 3º e o 4º.
      final remaining = RoutePathTrimmer.remaining(
        points: points,
        current: points[2],
      );
      expect(remaining, hasLength(2));
      expect(remaining.first.latitude, points[2].latitude);
      expect(remaining.last.latitude, points[3].latitude);
    });

    test('posição entre pontos usa o ponto mais próximo', () {
      // Um pouco depois do 3º ponto, ainda mais perto dele do que do 4º.
      const current =
          GeoPointEntity(latitude: -23.5521, longitude: -46.6351);
      final remaining = RoutePathTrimmer.remaining(
        points: points,
        current: current,
      );
      expect(remaining, hasLength(2));
      expect(remaining.first.latitude, points[2].latitude);
    });

    test('usuário no destino mantém apenas o último ponto', () {
      final remaining = RoutePathTrimmer.remaining(
        points: points,
        current: points.last,
      );
      expect(remaining, hasLength(1));
      expect(remaining.single.latitude, points.last.latitude);
    });
  });
}