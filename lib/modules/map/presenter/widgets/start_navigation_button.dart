import 'package:flutter/material.dart';

import '../../../../modules/core/theme/domain/app_theme.dart';
import '../../../../modules/core/theme/domain/tokens/app_spacing.dart';

/// The **Iniciar** button shown over the map once a route is ready.
///
/// Tapping it starts navigation: continuous location tracking, camera
/// following the user and the polyline trimmed to the path ahead. Pure
/// component — receives the action callback from the parent (View), never
/// touching repositories, services or the ViewModel.
class StartNavigationButton extends StatelessWidget {
  const StartNavigationButton({super.key, required this.onPressed});

  /// Action triggered when the user taps [Iniciar].
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: AppTheme.primaryCtaButtonStyle(),
              onPressed: onPressed,
              icon: const Icon(Icons.navigation, size: 20),
              label: const Text('Iniciar'),
            ),
          ),
        ),
      ),
    );
  }
}