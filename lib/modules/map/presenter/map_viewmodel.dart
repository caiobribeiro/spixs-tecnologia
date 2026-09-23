import 'package:flutter/foundation.dart';

import '../../../../shared/patterns/command.dart';
import '../../../../shared/patterns/result.dart';
import '../domain/entity/place_entity.dart';
import '../domain/entity/route_entity.dart';
import '../domain/entity/route_request_entity.dart';
import '../domain/repository/map_repository.dart';

/// Manages the state and logic of the map screen.
///
/// Exposes [Command]s to perform actions and reads the module SSOT through
/// the [MapRepository] contract. It never depends on the repository
/// implementation directly.
class MapViewmodel extends ChangeNotifier {
  MapViewmodel(this._repository);

  final MapRepository _repository;

  late final getPlacesCommand = Command0<List<PlaceEntity>>(
    _repository.getPlaces,
  );

  late final getRouteCommand = Command1<RouteEntity, RouteRequestEntity>(
    _repository.computeRoute,
  );

  /// The latest places loaded by [getPlacesCommand], if any.
  List<PlaceEntity>? get places {
    final result = getPlacesCommand.result;
    if (result is Ok<List<PlaceEntity>>) {
      return result.value;
    }
    return null;
  }

  /// SSOT da rota calculada (vive no [MapRepositoryImpl]).
  ValueNotifier<RouteEntity?> get route => _repository.route;

  /// Loads the places shown on the map.
  Future<void> loadPlaces() => getPlacesCommand.execute();

  /// Computes a route for the addresses collected on the form.
  Future<void> loadRoute(RouteRequestEntity request) {
    return getRouteCommand.execute(request);
  }
}