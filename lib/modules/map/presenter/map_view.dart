import 'package:flutter/material.dart';

/// Map screen entry point.
///
/// Coordinates layout, navigation and the [MapViewmodel] listeners.
/// Intentionally minimal: the map UI (GoogleMap, markers, routes) will be
/// composed in this view and its feature widgets under `widgets/` as the
/// feature evolves.
class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Map'),
      ),
    );
  }
}