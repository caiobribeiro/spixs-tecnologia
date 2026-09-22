import 'package:flutter/material.dart';

import 'home_view.dart';

/// Routes owned by the home module.
enum HomeRoute { home }

extension HomeRoutePath on HomeRoute {
  /// Route path registered by the home module.
  String get path {
    switch (this) {
      case HomeRoute.home:
        return '/';
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
  }
}