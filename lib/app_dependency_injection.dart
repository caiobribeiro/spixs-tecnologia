import 'package:get_it/get_it.dart';

import 'modules/core/theme/domain/app_theme.dart';
import 'modules/core/theme/domain/repository/theme_repository.dart';
import 'modules/core/theme/domain/repository/theme_repository_impl.dart';
import 'modules/home/data/services/home_service.dart';
import 'modules/home/domain/repository/home_repository.dart';
import 'modules/home/domain/repository/home_repository_impl.dart';
import 'modules/home/presenter/home_viewmodel.dart';
import 'modules/map/data/services/map_service.dart';
import 'modules/map/domain/repository/map_repository.dart';
import 'modules/map/domain/repository/map_repository_impl.dart';
import 'modules/map/presenter/map_viewmodel.dart';

final getIt = GetIt.instance;

/// Registers every service, repository and viewmodel in the app.
///
/// Services and repositories are lazy singletons: a single shared instance
/// per dependency. ViewModels are factories: a fresh instance per screen.
void setupDependencyInjection() {
  // ---- Core: theme (single source of truth do tema) ----
  getIt.registerLazySingleton<ThemeRepository>(
    () => ThemeRepositoryImpl(AppTheme.build()),
  );

  // ---- Home module ----
  getIt.registerLazySingleton<HomeService>(() => HomeService());
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(getIt<HomeService>()),
  );
  getIt.registerFactory<HomeViewmodel>(
    () => HomeViewmodel(getIt<HomeRepository>()),
  );

  // ---- Map module ----
  getIt.registerLazySingleton<MapService>(() => MapService());
  getIt.registerLazySingleton<MapRepository>(
    () => MapRepositoryImpl(getIt<MapService>()),
  );
  getIt.registerFactory<MapViewmodel>(
    () => MapViewmodel(getIt<MapRepository>()),
  );
}