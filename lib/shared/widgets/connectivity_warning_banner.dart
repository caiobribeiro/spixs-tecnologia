import 'package:flutter/material.dart';

import '../../modules/core/theme/domain/tokens/app_colors.dart';
import '../../modules/core/theme/domain/tokens/app_radii.dart';
import '../../modules/core/theme/domain/tokens/app_spacing.dart';
import '../../modules/core/theme/domain/tokens/app_typography.dart';

class ConnectivityWarningBanner extends StatelessWidget {
  const ConnectivityWarningBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? null : double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: compact ? AppSpacing.space2 : AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface200,
        borderRadius: BorderRadius.circular(AppRadii.radiusSm),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Icon(
            Icons.wifi_off,
            size: compact ? 16 : 20,
            color: AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.space2),
          Flexible(
            child: Text(
              'Sem conexão com a internet',
              style: AppTypography.caption.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
