import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spixs_tecnologia/app_dependency_injection.dart';

import '../../../../modules/core/connectivity/domain/repository/connectivity_repository.dart';
import '../../../../shared/patterns/command.dart';
import '../../../../shared/patterns/result.dart';
import '../../domain/entity/geo_point_entity.dart';
import '../../domain/entity/location_access_status.dart';
import '../../domain/entity/place_entity.dart';
import '../../domain/entity/route_entity.dart';
import '../../domain/entity/route_request_entity.dart';
import '../../domain/location_access_failure.dart';
import '../../domain/repository/location_repository.dart';
import '../../domain/repository/map_repository.dart';
import '../../domain/usecases/detect_route_completion_use_case.dart';
import '../../domain/usecases/detect_route_deviation_use_case.dart';
import '../../domain/usecases/find_unvisited_stops_use_case.dart';
import '../../domain/usecases/numbered_marker_use_case.dart';
import '../../domain/usecases/trim_route_path_use_case.dart';

class MapViewmodel extends ChangeNotifier {
  MapViewmodel(
    this._repository,
    this._locationRepository,
    this._trimRoutePath,
    this._markerIcons,
    this._detectRouteDeviation,
    this._findUnvisitedStops,
    this._detectRouteCompletion, {
    this._connectivityRepository,
  });

  final MapRepository _repository;
  final LocationRepository _locationRepository;
  final TrimRoutePathUseCase _trimRoutePath;
  final NumberedMarkerUseCase _markerIcons;
  final DetectRouteDeviationUseCase _detectRouteDeviation;
  final FindUnvisitedStopsUseCase _findUnvisitedStops;
  final DetectRouteCompletionUseCase _detectRouteCompletion;

  ConnectivityRepository? _connectivityRepository;
  ConnectivityRepository get _connectivityRepo =>
      _connectivityRepository ??= getIt<ConnectivityRepository>();

  ValueListenable<bool> get isOnline => _connectivityRepo.isOnline;

  Future<void> startConnectivityMonitoring() =>
      _connectivityRepo.startMonitoring();

  List<String>? _addresses;

  bool _routeComputed = false;

  final ValueNotifier<LocationAccessStatus> locationStatus =
      ValueNotifier<LocationAccessStatus>(LocationAccessStatus.checking);

  final ValueNotifier<bool> navigating = ValueNotifier<bool>(false);

  final ValueNotifier<int> routeRecalculationCount = ValueNotifier<int>(0);

  final ValueNotifier<bool> routeFinished = ValueNotifier<bool>(false);

  final Set<int> _visitedStopIndexes = <int>{};

  late final initializeLocationCommand = Command0<GeoPointEntity>(
    _requestLocationAccess,
  );

  late final getPlacesCommand = Command0<List<PlaceEntity>>(
    _repository.getPlaces,
  );

  late final getRouteCommand = Command1<RouteEntity, RouteRequestEntity>(
    _repository.computeRoute,
  );

  ValueNotifier<GeoPointEntity?> get startPoint =>
      _locationRepository.startPoint;

  List<GeoPointEntity> get remainingPolylinePoints {
    final route = _repository.route.value;
    if (route == null) {
      return const [];
    }
    final position = startPoint.value;
    if (!navigating.value || position == null) {
      return route.polylinePoints;
    }
    return _trimRoutePath.execute(
      points: route.polylinePoints,
      currentPosition: position,
    );
  }

  List<PlaceEntity>? get places {
    final result = getPlacesCommand.result;
    if (result is Ok<List<PlaceEntity>>) {
      return result.value;
    }
    return null;
  }

  ValueNotifier<RouteEntity?> get route => _repository.route;

  Future<void> initializeRoute(List<String> addresses) {
    _addresses = addresses;
    return _computeRouteWithUserOrigin();
  }

  Future<void> initializeLocation() {
    return initializeLocationCommand.execute();
  }

  void startNavigation() {
    if (navigating.value) {
      return;
    }
    navigating.value = true;
    _locationRepository.startLocationUpdates();
    _locationRepository.startPoint.addListener(_onPositionChanged);
  }

  Future<BitmapDescriptor> numberedMarkerIcon(int number) {
    return _markerIcons.execute(number);
  }

  Future<void> enableLocation() async {
    await _locationRepository.openLocationSettings();
    await initializeLocation();
  }

  Future<void> grantLocationPermission() async {
    if (await _locationRepository.canRequestPermission()) {
      await initializeLocation();
    } else {
      await _locationRepository.openAppSettings();
      await initializeLocation();
    }
  }

  Future<void> loadPlaces() => getPlacesCommand.execute();

  Future<void> _computeRouteWithUserOrigin() async {
    final origin = startPoint.value;
    final addresses = _addresses;
    if (_routeComputed ||
        origin == null ||
        addresses == null ||
        addresses.isEmpty ||
        getRouteCommand.running) {
      return;
    }
    _routeComputed = true;
    await getRouteCommand.execute(
      RouteRequestEntity(addresses: addresses, origin: origin),
    );
  }

  Future<Result<GeoPointEntity>> _requestLocationAccess() async {
    locationStatus.value = LocationAccessStatus.checking;
    final result = await _locationRepository.requestLocationAccess();

    switch (result) {
      case Ok<GeoPointEntity>():
        locationStatus.value = LocationAccessStatus.ready;
        _locationRepository.startLocationUpdates();

        unawaited(_computeRouteWithUserOrigin());
        return result;
      case Error<GeoPointEntity>():
        final error = result.error;
        if (error is LocationServiceDisabledFailure) {
          locationStatus.value = LocationAccessStatus.serviceDisabled;
        } else if (error is LocationPermissionDeniedFailure) {
          locationStatus.value = LocationAccessStatus.denied;
        } else {
          locationStatus.value = LocationAccessStatus.failed;
        }
        return result;
    }
  }

  void _onPositionChanged() {
    if (!navigating.value || routeFinished.value) {
      return;
    }
    final route = _repository.route.value;
    final position = startPoint.value;
    if (route == null || position == null) {
      return;
    }

    _trackVisitedStops(position);

    if (_detectRouteCompletion.execute(
      polylinePoints: route.polylinePoints,
      position: position,
    )) {
      routeFinished.value = true;
      return;
    }

    final remainingPoints = remainingPolylinePoints;
    if (!_detectRouteDeviation.execute(
      routePoints: remainingPoints,
      position: position,
    )) {
      return;
    }
    unawaited(_recalculateRoute(position));
  }

  void _trackVisitedStops(GeoPointEntity position) {
    final route = _repository.route.value;
    if (route == null) {
      return;
    }
    final stopOffset = route.startsFromUserLocation ? 1 : 0;
    final stops = route.waypoints.sublist(stopOffset);
    if (stops.isEmpty) {
      return;
    }

    final unvisited = _findUnvisitedStops.execute(
      waypoints: stops,
      position: position,
    );
    for (var i = 0; i < stops.length; i++) {
      if (!unvisited.contains(stops[i])) {
        _visitedStopIndexes.add(i);
      }
    }
  }

  Future<void> _recalculateRoute(GeoPointEntity position) async {
    if (getRouteCommand.running) {
      return;
    }
    final route = _repository.route.value;
    if (route == null) {
      return;
    }

    final stopOffset = route.startsFromUserLocation ? 1 : 0;
    final stops = route.waypoints.sublist(stopOffset);
    final remainingAddresses = <String>[
      for (var i = 0; i < stops.length; i++)
        if (!_visitedStopIndexes.contains(i)) stops[i].address,
    ];
    if (remainingAddresses.isEmpty) {
      return;
    }

    await getRouteCommand.execute(
      RouteRequestEntity(addresses: remainingAddresses, origin: position),
    );
    if (getRouteCommand.completed) {
      routeRecalculationCount.value++;

      _visitedStopIndexes.clear();
      routeFinished.value = false;
    }
  }

  @override
  void dispose() {
    _locationRepository.startPoint.removeListener(_onPositionChanged);
    _locationRepository.stopLocationUpdates();
    locationStatus.dispose();
    navigating.dispose();
    routeRecalculationCount.dispose();
    routeFinished.dispose();
    super.dispose();
  }
}
