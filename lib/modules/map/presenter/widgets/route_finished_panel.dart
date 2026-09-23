import 'package:flutter/material.dart';

import '../../../core/theme/domain/app_theme.dart';
import '../../../core/theme/domain/tokens/app_colors.dart';
import '../../../core/theme/domain/tokens/app_radii.dart';
import '../../../core/theme/domain/tokens/app_spacing.dart';
import '../../../core/theme/domain/tokens/app_typography.dart';

/// Panel shown over the map when the user has **completed the whole route**
/// (reached the end of the polyline — the destination): the navigation is
/// finished and the user can go back to the routes form, clearing its state.
///
/// Pure component: receives the action callback from the parent View — it
/// never touches repositories, services or the ViewModel.
class RouteFinishedPanel extends StatelessWidget {
  const RouteFinishedPanel({super.key, required this.onGoBack});

  /// Action triggered when the user taps [Voltar]: goes back to the routes
  /// form view, clearing the filled form state.
  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.space3),
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.surface200,
            borderRadius: BorderRadius.circular(AppRadii.radiusMd),
            border: Border.all(color: AppColors.success),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 40,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text('Trajeto concluído', style: AppTypography.heading),
              const SizedBox(height: AppSpacing.space1),
              Text(
                'Você fez todo o trajeto e chegou ao destino final.',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: AppTheme.primaryCtaButtonStyle(),
                  onPressed: onGoBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Voltar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}