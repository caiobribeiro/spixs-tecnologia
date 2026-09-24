import 'package:flutter/material.dart';

import 'home_view/home_view.dart';
import 'routes_form_view/routes_form_view.dart';

enum HomeRoute { home, form }

extension HomeRoutePath on HomeRoute {
  String get path {
    switch (this) {
      case HomeRoute.home:
        return '/';
      case HomeRoute.form:
        return '/form';
    }
  }
}

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
