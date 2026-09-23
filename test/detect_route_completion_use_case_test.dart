// Testes do DetectRouteCompletionUseCase: detecta quando o usuário fez
// todo o trajeto — chegou ao fim da polyline (destino final) dentro de um
// raio de conclusão.

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/calculate_geographic_distance_use_case.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/detect_route_completion_use_case.dart';

void main() {
  final useCase =
      DetectRouteCompletionUseCase(CalculateGeographicDistanceUseCase());

  // 0.001° de latitude ≈ 111m.
  const origin = GeoPointEntity(latitude: -23.5505, longitude: -46.6333);
  const destination = GeoPointEntity(latitude: -23.5530, longitude: -46.6360);
  const polyline = [origin, destination];

  group('DetectRouteCompletionUseCase', () {
    test('posição sobre o último ponto da polyline conclui o trajeto', () {
      expect(
        useCase.execute(polylinePoints: polyline, position: destination),
        isTrue,
      );
    });

    test('posição dentro do raio de conclusão (50m) conclui', () {
      // ~33m antes do destino.
      const near = GeoPointEntity(latitude: -23.5527, longitude: -46.6360);
      expect(
        useCase.execute(polylinePoints: polyline, position: near),
        isTrue,
      );
    });

    test('posição longe do fim da polyline não conclui', () {
      // Na origem do trajeto (~277m do destino).
      expect(
        useCase.execute(polylinePoints: polyline, position: origin),
        isFalse,
      );
    });

    test('polyline vazia nunca conclui (sem destino para comparar)', () {
      expect(
        useCase.execute(polylinePoints: const [], position: destination),
        isFalse,
      );
    });

    test('raio customizado é respeitado', () {
      // ~100m antes do destino.
      const middle = GeoPointEntity(latitude: -23.5521, longitude: -46.6360);
      expect(
        useCase.execute(
          polylinePoints: polyline,
          position: middle,
          radiusMeters: 150,
        ),
        isTrue,
      );
      expect(
        useCase.execute(
          polylinePoints: polyline,
          position: middle,
          radiusMeters: 50,
        ),
        isFalse,
      );
    });
  });
}