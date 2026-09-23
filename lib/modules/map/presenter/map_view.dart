import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app_dependency_injection.dart';
import '../../../modules/core/theme/domain/tokens/app_colors.dart';
import '../../../modules/core/theme/domain/tokens/app_spacing.dart';
import '../../../modules/core/theme/domain/tokens/app_typography.dart';
import '../domain/entity/geo_point_entity.dart';
import '../domain/entity/location_access_status.dart';
import '../domain/entity/route_entity.dart';
import 'helpers/map_marker_helper.dart';
import 'map_viewmodel.dart';
import 'widgets/location_warning_card.dart';

/// Map screen entry point.
///
/// Renders the Google Map centered on the user's current location, marked
/// as the route **start point**. When a route has been computed it also
/// draws the optimized polyline, numbered waypoint markers and a GPS
/// marker that moves as the device location updates.
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapViewmodel _viewmodel = getIt<MapViewmodel>();

  GoogleMapController? _mapController;

  /// Icons for numbered waypoint markers, generated asynchronously.
  final Map<int, BitmapDescriptor> _numberedIcons = {};

  /// Câmera inicial (fallback) exibida enquanto a localização do usuário
  /// ainda não foi obtida.
  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(-23.5505, -46.6333), // São Paulo
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _viewmodel.startPoint.addListener(_onStartPointChanged);
    _viewmodel.route.addListener(_onRouteChanged);
    _generateWaypointIcons();
    _viewmodel.initializeLocation();
  }

  @override
  void dispose() {
    _viewmodel.startPoint.removeListener(_onStartPointChanged);
    _viewmodel.route.removeListener(_onRouteChanged);
    _viewmodel.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Centraliza a câmera na localização atual assim que ela chega ao SSOT.
  void _onStartPointChanged() {
    final point = _viewmodel.startPoint.value;
    if (point == null) {
      return;
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(point.latitude, point.longitude),
        15,
      ),
    );
  }

  /// Rebuilds markers when the route changes.
  void _onRouteChanged() {
    _generateWaypointIcons().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Generates numbered marker icons for every waypoint in the current route.
  Future<void> _generateWaypointIcons() async {
    final route = _viewmodel.route.value;
    if (route == null) {
      _numberedIcons.clear();
      return;
    }

    final futures = <Future<void>>[];
    for (var i = 0; i < route.waypoints.length; i++) {
      futures.add(
        MapMarkerHelper.numberedMarker(i + 1).then((icon) {
          _numberedIcons[i] = icon;
        }),
      );
    }
    await Future.wait(futures);
  }

  /// Marcadores: waypoints numerados + marcador GPS de cor diferente.
  Set<Marker> _buildMarkers(GeoPointEntity? gpsPoint, RouteEntity? route) {
    final markers = <Marker>{};

    // Marcador GPS — cor diferente (azul) e atualizado em tempo real.
    if (gpsPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('gpsLocation'),
          position: LatLng(gpsPoint.latitude, gpsPoint.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Sua localização'),
          zIndexInt: 2,
        ),
      );
    }

    // Marcadores dos waypoints na ordem otimizada, com numeração.
    if (route != null) {
      for (var i = 0; i < route.waypoints.length; i++) {
        final waypoint = route.waypoints[i];
        markers.add(
          Marker(
            markerId: MarkerId('waypoint_$i'),
            position: LatLng(
              waypoint.location.latitude,
              waypoint.location.longitude,
            ),
            icon: _numberedIcons[i] ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
            infoWindow: InfoWindow(
              title: '${i + 1}º parada',
              snippet: waypoint.address,
            ),
            zIndexInt: 1,
          ),
        );
      }
    }

    return markers;
  }

  /// Polyline traçada sobre o mapa seguindo a rota otimizada.
  Set<Polyline> _buildPolylines(RouteEntity? route) {
    if (route == null || route.polylinePoints.isEmpty) {
      return const {};
    }
    return {
      Polyline(
        polylineId: const PolylineId('optimizedRoute'),
        points: route.polylinePoints
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
        color: AppColors.brand,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<GeoPointEntity?>(
        valueListenable: _viewmodel.startPoint,
        builder: (context, startPoint, _) {
          return ValueListenableBuilder<RouteEntity?>(
            valueListenable: _viewmodel.route,
            builder: (context, route, _) {
              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: _initialCamera,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // A localização pode chegar antes do mapa estar pronto.
                      _onStartPointChanged();
                    },
                    markers: _buildMarkers(startPoint, route),
                    polylines: _buildPolylines(route),
                  ),
                  _buildLocationStatusOverlay(),
                  _buildRouteOrderOverlay(route),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Overlay que exibe a ordem otimizada dos pontos com numeração.
  Widget _buildRouteOrderOverlay(RouteEntity? route) {
    if (route == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.space3),
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.surface200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ordem otimizada',
                style: AppTypography.bodyStrong,
              ),
              const SizedBox(height: AppSpacing.space2),
              for (var i = 0; i < route.waypoints.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: AppSpacing.space2),
                        decoration: const BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          route.waypoints[i].address,
                          style: AppTypography.body,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Estado do fluxo de localização sobre o mapa: carregamento, avisos
  /// (permissão negada / GPS desligado) com a ação de recuperação.
  Widget _buildLocationStatusOverlay() {
    return ValueListenableBuilder<LocationAccessStatus>(
      valueListenable: _viewmodel.locationStatus,
      builder: (context, status, _) {
        final command = _viewmodel.initializeLocationCommand;

        switch (status) {
          case LocationAccessStatus.checking:
            return Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.space3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface200,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        'Obtendo sua localização...',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ),
            );

          case LocationAccessStatus.ready:
            return const SizedBox.shrink();

          case LocationAccessStatus.denied:
            return Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: LocationWarningCard(
                  icon: Icons.location_off,
                  iconColor: AppColors.danger,
                  title: 'Permissão de localização negada',
                  message: 'Para definir seu ponto de partida, conceda a '
                      'permissão de localização ao Spixs Tecnologia.',
                  buttonLabel: 'Permitir localização',
                  working: command.running,
                  onPressed: _viewmodel.grantLocationPermission,
                ),
              ),
            );

          case LocationAccessStatus.serviceDisabled:
            return Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: LocationWarningCard(
                  icon: Icons.gps_off,
                  iconColor: AppColors.warning,
                  title: 'GPS desligado',
                  message: 'Ligue o GPS para centralizar o mapa na sua '
                      'localização atual e definir o ponto de partida.',
                  buttonLabel: 'Ligar GPS',
                  working: command.running,
                  onPressed: _viewmodel.enableLocation,
                ),
              ),
            );

          case LocationAccessStatus.failed:
            return Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: LocationWarningCard(
                  icon: Icons.error_outline,
                  iconColor: AppColors.danger,
                  title: 'Não foi possível obter a localização',
                  message: 'Verifique se o GPS está ligado e tente '
                      'novamente.',
                  buttonLabel: 'Tentar novamente',
                  working: command.running,
                  onPressed: _viewmodel.initializeLocation,
                ),
              ),
            );
        }
      },
    );
  }
}
