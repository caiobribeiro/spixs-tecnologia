import 'package:flutter/material.dart';

import 'app_dependency_injection.dart';
import 'app_routes.dart';
import 'modules/core/theme/domain/repository/theme_repository.dart';

class SpixsTecnologiaApp extends StatelessWidget {
  const SpixsTecnologiaApp({super.key, this.theme});

  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spixs Tecnologia',
      debugShowCheckedModeBanner: false,
      theme: theme ?? getIt<ThemeRepository>().theme,

      themeMode: ThemeMode.light,
      initialRoute: AppRoute.home.path,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
