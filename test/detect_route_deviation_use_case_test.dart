// Testes do DetectRouteDeviationUseCase: detecta quando o usuário se
// distancia da rota planejada além de um threshold de distância.

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/calculate_geographic_distance_use_case.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/detect_route_deviation_use_case.dart';

void main() {
  final useCase =
      DetectRouteDeviationUseCase(CalculateGeographicDistanceUseCase());

  // 0.0009° de latitude ≈ 100m (distância aproximada usada nos testes).
  const origin = GeoPointEntity(latitude: -23.5505, longitude: -46.6333);
  const onRoute = GeoPointEntity(latitude: -23.5505, longitude: -46.6334);
  // ~222m ao norte do origin — além do threshold padrão (150m).
  const deviated = GeoPointEntity(latitude: -23.5485, longitude: -46.6333);
  // ~55m ao norte do origin — dentro do threshold padrão.
  const nearRoute = GeoPointEntity(latitude: -23.5500, longitude: -46.6333);

  group('DetectRouteDeviationUseCase', () {
    test('posição sobre o próprio caminho não é desvio', () {
      expect(
        useCase.execute(routePoints: const [origin, onRoute], position: origin),
        isFalse,
      );
    });

    test('posição dentro do threshold não é desvio', () {
      expect(
        useCase.execute(routePoints: const [origin], position: nearRoute),
        isFalse,
      );
    });

    test('posição além do threshold é desvio', () {
      expect(
        useCase.execute(routePoints: const [origin], position: deviated),
        isTrue,
      );
    });

    test('usa o ponto mais próximo do trajeto, não a média', () {
      // Posição longe de um ponto, mas colada no outro → sem desvio.
      expect(
        useCase.execute(
          routePoints: const [deviated, onRoute],
          position: deviated,
        ),
        isFalse,
      );
    });

    test('polyline vazia nunca dispara desvio (nada a comparar)', () {
      expect(
        useCase.execute(routePoints: const [], position: deviated),
        isFalse,
      );
    });

    test('threshold customizado é respeitado', () {
      // ~100m do origin.
      const position = GeoPointEntity(
        latitude: -23.5496,
        longitude: -46.6333,
      );
      expect(
        useCase.execute(
          routePoints: const [origin],
          position: position,
          thresholdMeters: 60,
        ),
        isTrue,
      );
      expect(
        useCase.execute(
          routePoints: const [origin],
          position: position,
          thresholdMeters: 200,
        ),
        isFalse,
      );
    });
  });
}