import 'package:flutter/material.dart';

import 'app_dependency_injection.dart';
import 'app_routes.dart';
import 'modules/core/theme/domain/repository/theme_repository.dart';

/// Root widget of the Spixs Tecnologia app.
///
/// The root app does not hold feature logic: it only composes the
/// MaterialApp, applies the theme (design system Rota) and configures
/// the module routes.
class SpixsTecnologiaApp extends StatelessWidget {
  const SpixsTecnologiaApp({super.key, this.theme});

  /// Tema injetado (usado por testes). Quando nulo, o tema do design
  /// system é resolvido via [ThemeRepository] (single source of truth).
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spixs Tecnologia',
      debugShowCheckedModeBanner: false,
      theme: theme ?? getIt<ThemeRepository>().theme,
      // O design system define apenas o tema claro.
      themeMode: ThemeMode.light,
      initialRoute: AppRoute.home.path,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}