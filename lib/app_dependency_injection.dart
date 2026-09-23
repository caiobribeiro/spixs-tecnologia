import 'package:get_it/get_it.dart';

import 'app_config.dart';
import 'modules/core/auth/data/services/auth_service.dart';
import 'modules/core/auth/domain/repository/auth_repository.dart';
import 'modules/core/auth/domain/repository/auth_repository_impl.dart';
import 'modules/core/connectivity/data/services/connectivity_service.dart';
import 'modules/core/connectivity/domain/repository/connectivity_repository.dart';
import 'modules/core/connectivity/domain/repository/connectivity_repository_impl.dart';
import 'modules/core/theme/domain/app_theme.dart';
import 'modules/core/theme/domain/repository/theme_repository.dart';
import 'modules/core/theme/domain/repository/theme_repository_impl.dart';
import 'modules/home/data/services/home_service.dart';
import 'modules/home/data/services/places_service.dart';
import 'modules/home/domain/repository/home_repository.dart';
import 'modules/home/domain/repository/home_repository_impl.dart';
import 'modules/home/domain/repository/places_repository.dart';
import 'modules/home/domain/repository/places_repository_impl.dart';
import 'modules/home/presenter/home_view/home_viewmodel.dart';
import 'modules/home/presenter/routes_form_view/routes_form_viewmodel.dart';
import 'modules/map/data/services/geocoding_service.dart';
import 'modules/map/data/services/location_service.dart';
import 'modules/map/data/services/map_service.dart';
import 'modules/map/domain/repository/location_repository.dart';
import 'modules/map/domain/repository/location_repository_impl.dart';
import 'modules/map/domain/repository/map_repository.dart';
import 'modules/map/domain/repository/map_repository_impl.dart';
import 'modules/map/domain/usecases/calculate_geographic_distance_use_case.dart';
import 'modules/map/domain/usecases/detect_route_completion_use_case.dart';
import 'modules/map/domain/usecases/detect_route_deviation_use_case.dart';
import 'modules/map/domain/usecases/find_unvisited_stops_use_case.dart';
import 'modules/map/domain/usecases/numbered_marker_use_case.dart';
import 'modules/map/domain/usecases/sort_stops_by_distance_use_case.dart';
import 'modules/map/domain/usecases/trim_route_path_use_case.dart';
import 'modules/map/presenter/map_view/map_viewmodel.dart';

final getIt = GetIt.instance;

/// Registers every service, repository and viewmodel in the app.
///
/// Services and repositories are lazy singletons: a single shared instance
/// per dependency. ViewModels are factories: a fresh instance per screen.
void setupDependencyInjection() {
  // ---- Core: auth (gate de autenticação nativa) ----
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthService>()),
  );

  // ---- Core: theme (single source of truth do tema) ----
  getIt.registerLazySingleton<ThemeRepository>(
    () => ThemeRepositoryImpl(AppTheme.build()),
  );

  // ---- Core: connectivity (listener de internet; SSOT no repo) ----
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  getIt.registerLazySingleton<ConnectivityRepository>(
    () => ConnectivityRepositoryImpl(getIt<ConnectivityService>()),
  );

  // ---- Home module ----
  getIt.registerLazySingleton<HomeService>(() => HomeService());
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(getIt<HomeService>()),
  );
  // Autocomplete de endereços (Google Places) do formulário de rotas.
  getIt.registerLazySingleton<PlacesService>(
    () => PlacesService(apiKey: AppConfig.googlePlacesApiKey),
  );
  getIt.registerLazySingleton<PlacesRepository>(
    () => PlacesRepositoryImpl(getIt<PlacesService>()),
  );
  getIt.registerFactory<HomeViewmodel>(
    () => HomeViewmodel(getIt<HomeRepository>(), getIt<AuthRepository>()),
  );
  getIt.registerFactory<RoutesFormViewmodel>(
    () => RoutesFormViewmodel(
      placesRepository: getIt<PlacesRepository>(),
      connectivityRepository: getIt<ConnectivityRepository>(),
    ),
  );

  // ---- Map module ----
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(getIt<LocationService>()),
  );
  getIt.registerLazySingleton<MapService>(
    () => MapService(apiKey: AppConfig.googleMapsApiKey),
  );
  getIt.registerLazySingleton<GeocodingService>(
    () => GeocodingService(apiKey: AppConfig.googleMapsApiKey),
  );
  getIt.registerLazySingleton<MapRepository>(
    () => MapRepositoryImpl(
      getIt<MapService>(),
      getIt<GeocodingService>(),
      getIt<SortStopsByDistanceUseCase>(),
    ),
  );
  getIt.registerFactory<MapViewmodel>(
    () => MapViewmodel(
      getIt<MapRepository>(),
      getIt<LocationRepository>(),
      getIt<TrimRoutePathUseCase>(),
      getIt<NumberedMarkerUseCase>(),
      getIt<DetectRouteDeviationUseCase>(),
      getIt<FindUnvisitedStopsUseCase>(),
      getIt<DetectRouteCompletionUseCase>(),
      connectivityRepository: getIt<ConnectivityRepository>(),
    ),
  );

  // ---- Map module: use cases ----
  getIt.registerLazySingleton<CalculateGeographicDistanceUseCase>(
    () => CalculateGeographicDistanceUseCase(),
  );
  getIt.registerLazySingleton<SortStopsByDistanceUseCase>(
    () =>
        SortStopsByDistanceUseCase(getIt<CalculateGeographicDistanceUseCase>()),
  );
  getIt.registerLazySingleton<TrimRoutePathUseCase>(
    () => TrimRoutePathUseCase(),
  );
  getIt.registerLazySingleton<DetectRouteDeviationUseCase>(
    () => DetectRouteDeviationUseCase(
      getIt<CalculateGeographicDistanceUseCase>(),
    ),
  );
  getIt.registerLazySingleton<FindUnvisitedStopsUseCase>(
    () => FindUnvisitedStopsUseCase(
      getIt<CalculateGeographicDistanceUseCase>(),
    ),
  );
  getIt.registerLazySingleton<DetectRouteCompletionUseCase>(
    () => DetectRouteCompletionUseCase(
      getIt<CalculateGeographicDistanceUseCase>(),
    ),
  );
  getIt.registerLazySingleton<NumberedMarkerUseCase>(
    () => NumberedMarkerUseCase(),
  );
}
