import '../entity/geo_point_entity.dart';
import '../entity/route_stop_entity.dart';
import 'calculate_geographic_distance_use_case.dart';

class SortStopsByDistanceUseCase {
  SortStopsByDistanceUseCase(this._calculateDistance);

  final CalculateGeographicDistanceUseCase _calculateDistance;

  List<RouteStopEntity> execute({
    required GeoPointEntity origin,
    required List<RouteStopEntity> stops,
  }) {
    final sorted = List<RouteStopEntity>.of(stops);
    sorted.sort(
      (a, b) => _calculateDistance
          .execute(origin, a.location)
          .compareTo(_calculateDistance.execute(origin, b.location)),
    );
    return sorted;
  }
}
