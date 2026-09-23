import 'package:flutter/foundation.dart';

import '../../../../shared/patterns/result.dart';
import '../entity/place_entity.dart';
import '../entity/route_entity.dart';
import '../entity/route_request_entity.dart';

abstract interface class MapRepository {
  Future<Result<List<PlaceEntity>>> getPlaces();

  ValueNotifier<RouteEntity?> get route;

  Future<Result<RouteEntity>> computeRoute(RouteRequestEntity request);
}
