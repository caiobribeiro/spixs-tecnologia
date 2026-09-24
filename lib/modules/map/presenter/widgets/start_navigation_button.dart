import 'package:flutter/material.dart';

import '../../../../modules/core/theme/domain/app_theme.dart';
import '../../../../modules/core/theme/domain/tokens/app_spacing.dart';

class StartNavigationButton extends StatelessWidget {
  const StartNavigationButton({super.key, required this.onPressed});

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
