import 'package:flutter/material.dart';

import '../../../../modules/core/theme/domain/app_theme.dart';
import '../../../../modules/core/theme/domain/tokens/app_colors.dart';
import '../../../../modules/core/theme/domain/tokens/app_radii.dart';
import '../../../../modules/core/theme/domain/tokens/app_spacing.dart';
import '../../../../modules/core/theme/domain/tokens/app_typography.dart';

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

  final IconData icon;

  final Color iconColor;

  final String title;

  final String message;

  final String buttonLabel;

  final VoidCallback onPressed;

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
            Text(
              title,
              style: AppTypography.heading,
              textAlign: TextAlign.center,
            ),
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
