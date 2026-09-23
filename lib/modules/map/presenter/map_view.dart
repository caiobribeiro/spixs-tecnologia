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
import 'map_viewmodel.dart';
import 'widgets/location_warning_card.dart';
import 'widgets/start_navigation_button.dart';

/// Map screen entry point.
///
/// Receives the addresses collected on the route form ([addresses]) and
/// renders the Google Map centered on the user's current location, marked
/// as the route **start point**. On entry the route is computed **with the
/// user's location as origin** (plus the form addresses as optimized stops):
/// while it loads, a loading overlay is shown; when ready, the map draws the
/// optimized polyline, numbered stop markers and a GPS marker that moves as
/// the device location updates. The user's origin only uses the user marker
/// (never a numbered one).
///
/// Once the route is ready an **Iniciar** button is shown: on tap,
/// navigation starts — the camera follows the user continuously via the
/// location stream and the polyline is trimmed to the path still ahead
/// (the already traveled part is removed).
class MapView extends StatefulWidget {
  const MapView({super.key, this.addresses});

  /// Endereços preenchidos no formulário de rotas (A, B, C...), que viram
  /// pontos de parada da rota calculada a partir da localização do usuário.
  final List<String>? addresses;

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

  /// Se a câmera já foi centralizada na primeira fixação de localização.
  bool _hasCenteredOnUser = false;

  @override
  void initState() {
    super.initState();
    _viewmodel.startPoint.addListener(_onStartPointChanged);
    _viewmodel.route.addListener(_onRouteChanged);
    _generateWaypointIcons();
    // Entrada do mapa: repassa os endereços do formulário (a rota só é
    // calculada quando a localização do usuário chega) e pede a localização.
    unawaited(_viewmodel.initializeRoute(widget.addresses ?? const []));
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

  /// Centraliza a câmera na localização atual assim que ela chega ao SSOT
  /// (primeira fixação) e, durante a navegação, acompanha o usuário
  /// continuamente a cada atualização do stream de localização.
  void _onStartPointChanged() {
    final point = _viewmodel.startPoint.value;
    if (point == null) {
      return;
    }
    final cameraUpdate = CameraUpdate.newLatLngZoom(
      LatLng(point.latitude, point.longitude),
      15,
    );
    if (!_hasCenteredOnUser) {
      _hasCenteredOnUser = true;
      _mapController?.animateCamera(cameraUpdate);
      return;
    }
    // Navegação ativa: a câmera segue a posição do usuário em tempo real.
    if (_viewmodel.navigating.value) {
      _mapController?.animateCamera(cameraUpdate);
    }
  }

  /// Rebuilds markers when the route changes.
  void _onRouteChanged() {
    _generateWaypointIcons().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Generates numbered marker icons for every stop in the current route.
  ///
  /// Quando a rota começa na localização do usuário ([RouteEntity.userOrigin]),
  /// essa origem não recebe ícone numerado — o marcador do usuário é o GPS.
  Future<void> _generateWaypointIcons() async {
    final route = _viewmodel.route.value;
    if (route == null) {
      _numberedIcons.clear();
      return;
    }

    final markerOffset = route.startsFromUserLocation ? 1 : 0;
    final futures = <Future<void>>[];
    for (var i = markerOffset; i < route.waypoints.length; i++) {
      futures.add(
        _viewmodel.numberedMarkerIcon(i - markerOffset + 1).then((icon) {
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

    // Marcadores dos pontos de parada na ordem otimizada, com numeração.
    // A origem do usuário (quando a rota começa nela) só tem o marcador GPS.
    if (route != null) {
      final markerOffset = route.startsFromUserLocation ? 1 : 0;
      for (var i = markerOffset; i < route.waypoints.length; i++) {
        final waypoint = route.waypoints[i];
        final stopNumber = i - markerOffset + 1;
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
              title: '$stopNumberº parada',
              snippet: waypoint.address,
            ),
            zIndexInt: 1,
          ),
        );
      }
    }

    return markers;
  }

  /// Polyline desenhada sobre o mapa. Durante a navegação recebe somente o
  /// trecho ainda à frente do usuário ([MapViewmodel.remainingPolylinePoints]);
  /// antes do início, a rota completa.
  Set<Polyline> _buildPolylines(List<GeoPointEntity> points) {
    if (points.isEmpty) {
      return const {};
    }
    return {
      Polyline(
        polylineId: const PolylineId('optimizedRoute'),
        points: points
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
              return ValueListenableBuilder<bool>(
                valueListenable: _viewmodel.navigating,
                builder: (context, navigating, _) {
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
                        polylines: _buildPolylines(
                          _viewmodel.remainingPolylinePoints,
                        ),
                      ),
                      _buildLocationStatusOverlay(),
                      _buildRouteOrderOverlay(route),
                      // Por cima dos demais: visível mesmo com rota anterior ainda
                      // renderizada enquanto a nova é recalculada.
                      _buildRouteLoadingOverlay(),
                      // Botão "Iniciar": só aparece com rota pronta e antes de
                      // a navegação começar.
                      if (route != null && !navigating)
                        StartNavigationButton(
                          onPressed: _viewmodel.startNavigation,
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Overlay exibido enquanto a rota otimizada (com a localização do usuário
  /// como origem) é calculada na entrada do mapa.
  Widget _buildRouteLoadingOverlay() {
    return AnimatedBuilder(
      animation: _viewmodel.getRouteCommand,
      builder: (context, _) {
        if (!_viewmodel.getRouteCommand.running) {
          return const SizedBox.shrink();
        }
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
                    'Calculando melhor rota...',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Overlay que exibe a ordem otimizada dos pontos com numeração.
  ///
  /// A origem do usuário (quando a rota começa nela) não entra na lista,
  /// pois ela já é representada pelo marcador de localização do usuário.
  Widget _buildRouteOrderOverlay(RouteEntity? route) {
    if (route == null) {
      return const SizedBox.shrink();
    }

    final markerOffset = route.startsFromUserLocation ? 1 : 0;

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
              for (var i = markerOffset; i < route.waypoints.length; i++)
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
                          '${i - markerOffset + 1}',
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
