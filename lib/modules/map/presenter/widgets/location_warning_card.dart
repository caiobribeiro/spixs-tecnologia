import 'package:flutter/material.dart';

import '../../../../modules/core/theme/domain/app_theme.dart';
import '../../../../modules/core/theme/domain/tokens/app_colors.dart';
import '../../../../modules/core/theme/domain/tokens/app_radii.dart';
import '../../../../modules/core/theme/domain/tokens/app_spacing.dart';
import '../../../../modules/core/theme/domain/tokens/app_typography.dart';

/// Warning card shown over the map when the user's location cannot be
/// used (permission denied or GPS off).
///
/// Pure component: receives its content and the action callback from the
/// parent — it never touches repositories, services or the ViewModel.
class LocationWarningCard extends StatelessWidget {
  const LocationWarningCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    this.iconColor = AppColors.danger,
    this.working = false,
  });

  /// Icon leading the warning (e.g. `Icons.gps_off`).
  final IconData icon;

  /// Color of the leading icon (danger for blocked, warning for GPS off).
  final Color iconColor;

  /// Short title of the warning (e.g. "GPS desligado").
  final String title;

  /// Explanatory message with what the user should do.
  final String message;

  /// Label of the recovery action button.
  final String buttonLabel;

  /// Recovery action (e.g. open GPS settings and retry).
  final VoidCallback onPressed;

  /// Whether the recovery action is running (button shows progress).
  final bool working;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.space3),
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.surface200,
          borderRadius: BorderRadius.circular(AppRadii.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A12141A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: AppSpacing.space2),
            Text(title, style: AppTypography.heading, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.space1),
            Text(
              message,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space3),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppTheme.primaryCtaButtonStyle(),
                onPressed: working ? null : onPressed,
                child: working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}