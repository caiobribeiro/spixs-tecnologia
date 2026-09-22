import 'package:flutter/material.dart';

/// Home screen entry point.
///
/// Coordinates layout, navigation and the [HomeViewmodel] listeners.
/// Intentionally minimal: the dashboard UI will be composed in this view
/// and its feature widgets under `widgets/` as the feature evolves.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home'),
      ),
    );
  }
}