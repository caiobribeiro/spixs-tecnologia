import '../../../../shared/patterns/result.dart';
import '../../data/models/geo_point_model.dart';
import '../../data/models/place_model.dart';
import '../../data/models/route_model.dart';
import '../../data/services/map_service.dart';
import '../entity/place_entity.dart';
import '../entity/route_entity.dart';
import '../entity/route_request_entity.dart';
import 'map_repository.dart';

/// Concrete [MapRepository].
///
/// Delegates data access to the [MapService] (data layer) and converts
/// the `Model`s returned by the service into domain entities.
class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl(this._service);

  final MapService _service;

  @override
  Future<Result<List<PlaceEntity>>> getPlaces() async {
    final result = await _service.getPlaces();

    switch (result) {
      case Ok<List<PlaceModel>>():
        final value = result.value;
        return Result.ok(value.map((model) => model.toEntity()).toList());
      case Error<List<PlaceModel>>():
        final value = result;
        return Result.error(value.error);
    }
  }

  @override
  Future<Result<RouteEntity>> getRoute(RouteRequestEntity request) async {
    final result = await _service.getRoute(
      origin: GeoPointModel(
        latitude: request.origin.latitude,
        longitude: request.origin.longitude,
      ),
      destination: GeoPointModel(
        latitude: request.destination.latitude,
        longitude: request.destination.longitude,
      ),
    );

    switch (result) {
      case Ok<RouteModel>():
        final value = result.value;
        return Result.ok(value.toEntity());
      case Error<RouteModel>():
        final value = result;
        return Result.error(value.error);
    }
  }
}