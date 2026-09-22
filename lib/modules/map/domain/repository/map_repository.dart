import '../../../../shared/patterns/result.dart';
import '../entity/place_entity.dart';
import '../entity/route_entity.dart';
import '../entity/route_request_entity.dart';

/// Contract for the map module data source.
///
/// Declares the operations available to the presentation layer. The
/// concrete implementation lives in the same layer and owns the single
/// source of truth for the module data.
abstract interface class MapRepository {
  /// Loads the places displayed on the map.
  Future<Result<List<PlaceEntity>>> getPlaces();

  /// Computes a route for the given [request].
  Future<Result<RouteEntity>> getRoute(RouteRequestEntity request);
}