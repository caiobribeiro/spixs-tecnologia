import 'package:flutter/material.dart';

import 'modules/home/presenter/home_routes.dart';
import 'modules/map/presenter/map_routes.dart';

/// Application-level routing.
///
/// Imports and registers the routes exposed by every module. The module
/// files own their route paths and builders; this file only wires them.
enum AppRoute {
  home,
  form,
  map;

  /// Route path for the given [AppRoute], resolved through its module.
  String get path {
    switch (this) {
      case AppRoute.home:
        return HomeRoute.home.path;
      case AppRoute.form:
        return HomeRoute.form.path;
      case AppRoute.map:
        return MapRoute.map.path;
    }
  }
}

abstract final class AppRoutes {
  /// Generates the [Route] for a [RouteSettings] name.
  static Route<void> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return buildHomeRoute(HomeRoute.home, settings: settings);
      case '/form':
        return buildHomeRoute(HomeRoute.form, settings: settings);
      case '/map':
        return buildMapRoute(MapRoute.map, settings: settings);
      default:
        return buildHomeRoute(HomeRoute.home, settings: settings);
    }
  }
}