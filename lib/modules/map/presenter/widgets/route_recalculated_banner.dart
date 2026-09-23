import 'package:flutter/material.dart';

import '../../../core/theme/domain/tokens/app_colors.dart';
import '../../../core/theme/domain/tokens/app_radii.dart';
import '../../../core/theme/domain/tokens/app_spacing.dart';
import '../../../core/theme/domain/tokens/app_typography.dart';

/// Banner shown over the map after the route was **automatically
/// recalculated** (the user deviated from the planned path and the
/// navigation recomputed the route through the stops still to visit).
///
/// Pure component: receives the recalculation count from the parent View —
/// it never touches repositories, services or the ViewModel.
class RouteRecalculatedBanner extends StatelessWidget {
  const RouteRecalculatedBanner({
    super.key,
    required this.recalculationCount,
  });

  /// Number of automatic recalculations already performed during this
  /// navigation (drives the message: without the count on the first run).
  final int recalculationCount;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.space3),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface200,
            borderRadius: BorderRadius.circular(AppRadii.radiusSm),
            border: Border.all(color: AppColors.warning),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route, size: 16, color: AppColors.warning),
              const SizedBox(width: AppSpacing.space2),
              Text(
                recalculationCount > 1
                    ? 'Rota recalculada ($recalculationCount×)'
                    : 'Rota recalculada',
                style: AppTypography.caption.copyWith(color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}