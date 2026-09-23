import 'package:flutter/material.dart';

import 'home_view.dart';
import 'routes_form_view.dart';

/// Routes owned by the home module.
enum HomeRoute { home, form }

extension HomeRoutePath on HomeRoute {
  /// Route path registered by the home module.
  String get path {
    switch (this) {
      case HomeRoute.home:
        return '/';
      case HomeRoute.form:
        return '/form';
    }
  }
}

/// Builds the [Route] for a [HomeRoute].
///
/// The app-level routing must import this function to register the
/// home module routes.
Route<void> buildHomeRoute(HomeRoute route, {RouteSettings? settings}) {
  switch (route) {
    case HomeRoute.home:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const HomeView(),
      );
    case HomeRoute.form:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const RoutesFormView(),
      );
  }
}