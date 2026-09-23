import 'package:flutter/foundation.dart';

import '../../../../shared/patterns/result.dart';
import '../../data/models/geo_point_model.dart';
import '../../data/models/place_model.dart';
import '../../data/models/route_model.dart';
import '../../data/services/geocoding_service.dart';
import '../../data/services/map_service.dart';
import '../entity/geo_point_entity.dart';
import '../entity/place_entity.dart';
import '../entity/route_entity.dart';
import '../entity/route_request_entity.dart';
import '../entity/route_stop_entity.dart';
import '../usecases/sort_stops_by_distance_use_case.dart';
import 'map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl(
    this._service,
    this._geocodingService,
    this._sortStopsByDistance,
  );

  final MapService _service;
  final GeocodingService _geocodingService;
  final SortStopsByDistanceUseCase _sortStopsByDistance;

  final ValueNotifier<RouteEntity?> _route = ValueNotifier<RouteEntity?>(null);

  @override
  ValueNotifier<RouteEntity?> get route => _route;

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
  Future<Result<RouteEntity>> computeRoute(RouteRequestEntity request) async {
    final origin = request.origin;
    if (origin == null) {
      return _compute(request.addresses, origin: null);
    }

    final stopsResult = await _resolveStopsOrderedByDistance(
      request.addresses,
      origin,
    );
    switch (stopsResult) {
      case Ok<List<RouteStopEntity>>():
        final orderedAddresses = stopsResult.value
            .map((stop) => stop.address)
            .toList();
        return _compute(
          orderedAddresses,
          origin: GeoPointModel(
            latitude: origin.latitude,
            longitude: origin.longitude,
          ),
        );
      case Error<List<RouteStopEntity>>():
        final value = stopsResult;
        return Result.error(value.error);
    }
  }

  Future<Result<RouteEntity>> _compute(
    List<String> addresses, {
    GeoPointModel? origin,
  }) async {
    final result = await _service.computeRoute(addresses, origin: origin);

    switch (result) {
      case Ok<RouteModel>():
        final value = result.value.toEntity();

        _route.value = value;
        return Result.ok(value);
      case Error<RouteModel>():
        final value = result;
        return Result.error(value.error);
    }
  }

  Future<Result<List<RouteStopEntity>>> _resolveStopsOrderedByDistance(
    List<String> addresses,
    GeoPointEntity origin,
  ) async {
    if (addresses.isEmpty) {
      return const Result.ok([]);
    }

    final geocodeResults = await Future.wait<Result<GeoPointModel>>([
      for (final address in addresses)
        _geocodingService.geocodeAddress(address),
    ]);

    final stops = <RouteStopEntity>[];
    for (var i = 0; i < geocodeResults.length; i++) {
      final geocodeResult = geocodeResults[i];
      switch (geocodeResult) {
        case Ok<GeoPointModel>():
          stops.add(
            RouteStopEntity(
              address: addresses[i],
              location: geocodeResult.value.toEntity(),
            ),
          );
        case Error<GeoPointModel>():
          final value = geocodeResult;
          return Result.error(value.error);
      }
    }

    return Result.ok(
      _sortStopsByDistance.execute(origin: origin, stops: stops),
    );
  }
}
