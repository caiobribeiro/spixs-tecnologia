import 'package:flutter/foundation.dart';

import '../../../../shared/patterns/result.dart';
import '../entity/place_entity.dart';
import '../entity/route_entity.dart';
import '../entity/route_request_entity.dart';

/// Contract for the map module data source.
///
/// Declares the operations available to the presentation layer. The
/// concrete implementation (`MapRepositoryImpl`) owns the **single source
/// of truth (SSOT)** of the module data: [route] exposes the last computed
/// route, observable by the presentation layer.
abstract interface class MapRepository {
  /// Loads the places displayed on the map.
  Future<Result<List<PlaceEntity>>> getPlaces();

  /// SSOT da última rota calculada, pronta para a tela do mapa consumir.
  ValueNotifier<RouteEntity?> get route;

  /// Computes a route for the addresses in [request] using the Google
  /// Routes API, with intermediate waypoint optimization enabled
  /// (`optimizeWaypointOrder: true`).
  Future<Result<RouteEntity>> computeRoute(RouteRequestEntity request);
}