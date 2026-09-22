import 'package:flutter/material.dart';

import 'app_routes.dart';

/// Root widget of the Spixs Tecnologia app.
///
/// The root app does not hold feature logic: it only composes the
/// MaterialApp, applies the theme and configures the module routes.
class SpixsTecnologiaApp extends StatelessWidget {
  const SpixsTecnologiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spixs Tecnologia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: AppRoute.home.path,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}