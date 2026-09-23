import 'package:flutter_test/flutter_test.dart';
import 'package:spixs_tecnologia/modules/map/domain/entity/geo_point_entity.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/calculate_geographic_distance_use_case.dart';
import 'package:spixs_tecnologia/modules/map/domain/usecases/detect_route_deviation_use_case.dart';

void main() {
  test('probe', () {
    final useCase = DetectRouteDeviationUseCase(CalculateGeographicDistanceUseCase());
    const origin = GeoPointEntity(latitude: -23.5505, longitude: -46.6333);
    const nearRoute = GeoPointEntity(latitude: -23.5500, longitude: -46.6333);
    final result = useCase.execute(routePoints: const [origin], position: nearRoute);
    // ignore: avoid_print
    print('RESULT=$result threshold=${DetectRouteDeviationUseCase.deviationThresholdMeters}');
  });
}
