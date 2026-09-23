import 'package:flutter/material.dart';

import 'map_view/map_view.dart';

enum MapRoute { map }

extension MapRoutePath on MapRoute {
  String get path {
    switch (this) {
      case MapRoute.map:
        return '/map';
    }
  }
}

Route<void> buildMapRoute(MapRoute route, {RouteSettings? settings}) {
  switch (route) {
    case MapRoute.map:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) =>
            MapView(addresses: settings?.arguments as List<String>?),
      );
  }
}
