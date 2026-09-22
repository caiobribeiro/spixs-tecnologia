import 'package:flutter/material.dart';

import 'map_view.dart';

/// Routes owned by the map module.
enum MapRoute { map }

extension MapRoutePath on MapRoute {
  /// Route path registered by the map module.
  String get path {
    switch (this) {
      case MapRoute.map:
        return '/map';
    }
  }
}

/// Builds the [Route] for a [MapRoute].
///
/// The app-level routing must import this function to register the
/// map module routes.
Route<void> buildMapRoute(MapRoute route, {RouteSettings? settings}) {
  switch (route) {
    case MapRoute.map:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const MapView(),
      );
  }
}