import 'package:flutter/foundation.dart';

import '../../../../shared/patterns/command.dart';
import '../../../../shared/patterns/result.dart';
import '../domain/entity/geo_point_entity.dart';
import '../domain/entity/place_entity.dart';
import '../domain/entity/route_entity.dart';
import '../domain/entity/route_request_entity.dart';
import '../domain/repository/map_repository.dart';

/// Manages the state and logic of the map screen.
///
/// Exposes [Command]s to perform actions and reads data through the
/// [MapRepository] contract. It never depends on the repository
/// implementation directly.
class MapViewmodel extends ChangeNotifier {
  MapViewmodel(this._repository);

  final MapRepository _repository;

  late final getPlacesCommand = Command0<List<PlaceEntity>>(
    _repository.getPlaces,
  );

  late final getRouteCommand = Command1<RouteEntity, RouteRequestEntity>(
    _repository.getRoute,
  );

  /// The latest places loaded by [getPlacesCommand], if any.
  List<PlaceEntity>? get places {
    final result = getPlacesCommand.result;
    if (result is Ok<List<PlaceEntity>>) {
      return result.value;
    }
    return null;
  }

  /// The latest route loaded by [getRouteCommand], if any.
  RouteEntity? get route {
    final result = getRouteCommand.result;
    if (result is Ok<RouteEntity>) {
      return result.value;
    }
    return null;
  }

  /// Loads the places shown on the map.
  Future<void> loadPlaces() => getPlacesCommand.execute();

  /// Computes a route between [origin] and [destination].
  Future<void> loadRoute({
    required GeoPointEntity origin,
    required GeoPointEntity destination,
  }) {
    return getRouteCommand.execute(
      RouteRequestEntity(origin: origin, destination: destination),
    );
  }
}