import 'package:flutter/material.dart';

import '../../../core/theme/domain/app_theme.dart';
import '../../../core/theme/domain/tokens/app_colors.dart';
import '../../../core/theme/domain/tokens/app_spacing.dart';
import '../../../core/theme/domain/tokens/app_typography.dart';

/// Native authentication gate shown before the rest of the app is revealed.
///
/// Pure presentation: receives its state and the unlock callback from the
/// [HomeView]/[HomeViewmodel]. It never resolves dependencies, repositories
/// or services directly.
class AuthLockScreen extends StatelessWidget {
  const AuthLockScreen({
    super.key,
    required this.isAuthenticating,
    required this.onUnlock,
    this.errorMessage,
  });

  /// Whether the native authentication dialog is currently open.
  final bool isAuthenticating;

  /// Callback that triggers the native authentication.
  final VoidCallback onUnlock;

  /// Failure message from the last authentication attempt, if any.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // DS: tela de bloqueio em surface-200 (branco).
      backgroundColor: AppColors.surface200,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: AppColors.brand,
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                'Spixs Tecnologia',
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Confirme sua identidade com biometria, senha ou PIN do '
                'dispositivo para acessar o app.',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space4),
              if (isAuthenticating)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  style: AppTheme.primaryCtaButtonStyle(),
                  onPressed: onUnlock,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Desbloquear'),
                ),
              if (errorMessage != null) ...[
                const SizedBox(height: AppSpacing.space3),
                Text(
                  errorMessage!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.danger,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}