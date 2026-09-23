import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app_dependency_injection.dart';
import '../../../modules/core/theme/domain/tokens/app_colors.dart';
import '../../../modules/core/theme/domain/tokens/app_spacing.dart';
import '../../../modules/core/theme/domain/tokens/app_typography.dart';
import '../domain/entity/geo_point_entity.dart';
import '../domain/entity/location_access_status.dart';
import 'map_viewmodel.dart';
import 'widgets/location_warning_card.dart';

/// Map screen entry point.
///
/// Renders the Google Map centered on the user's current location, marked
/// as the route **start point**. While the location cannot be used —
/// permission denied or GPS off — a warning overlay offers the recovery
/// action (grant permission / turn GPS on).
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapViewmodel _viewmodel = getIt<MapViewmodel>();

  GoogleMapController? _mapController;

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
    _viewmodel.initializeLocation();
  }

  @override
  void dispose() {
    _viewmodel.startPoint.removeListener(_onStartPointChanged);
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

  /// Marcadores: apenas o ponto de partida (localização atual do usuário).
  Set<Marker> _buildMarkers(GeoPointEntity? startPoint) {
    if (startPoint == null) {
      return const {};
    }
    return {
      Marker(
        markerId: const MarkerId('startPoint'),
        position: LatLng(startPoint.latitude, startPoint.longitude),
        infoWindow: const InfoWindow(title: 'Ponto de partida'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<GeoPointEntity?>(
        valueListenable: _viewmodel.startPoint,
        builder: (context, startPoint, _) {
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _initialCamera,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // A localização pode chegar antes do mapa estar pronto.
                  _onStartPointChanged();
                },
                markers: _buildMarkers(startPoint),
              ),
              _buildLocationStatusOverlay(),
            ],
          );
        },
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