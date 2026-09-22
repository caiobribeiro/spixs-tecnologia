import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../../shared/patterns/result.dart';
import '../../domain/auth_failure.dart';

/// Native authentication through the `local_auth` plugin.
///
/// The feature is scoped to **Android and iOS**: on any other platform the
/// service reports that authentication is not available.
class AuthService {
  AuthService({LocalAuthentication? localAuthentication})
      : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  /// Whether the current platform is in the supported scope (Android / iOS).
  bool get isSupportedPlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Runs the native authentication dialog.
  ///
  /// Accepts biometrics and falls back to device credentials (PIN, pattern,
  /// passcode or password). Returns `true` when the user authenticates and
  /// `false` when the attempt is canceled or rejected without side effects.
  Future<Result<bool>> authenticate() async {
    if (!isSupportedPlatform) {
      return Result.ok(false);
    }

    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Autentique-se para acessar o app',
        // Senha, PIN ou padrão do dispositivo como alternativa à biometria.
        biometricOnly: false,
        // Mantém a tentativa em andamento se o app for para background.
        persistAcrossBackgrounding: true,
      );
      debugPrint('[Auth] authenticate -> $authenticated');
      return Result.ok(authenticated);
    } on LocalAuthException catch (error) {
      debugPrint(
        '[Auth] authenticate failed: ${error.code.name} '
        '(${error.description})',
      );
      return Result.error(AuthFailure(_messageFor(error.code)));
    } catch (error) {
      debugPrint('[Auth] authenticate threw: $error');
      return Result.error(
        AuthFailure('Falha na autenticação. Tente novamente.'),
      );
    }
  }

  String _messageFor(LocalAuthExceptionCode code) {
    switch (code) {
      case LocalAuthExceptionCode.noCredentialsSet:
        return 'Configure uma biometria, PIN ou senha no dispositivo para '
            'continuar.';
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        return 'Nenhuma biometria disponível. Use o PIN ou a senha do '
            'dispositivo.';
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
        return 'Autenticação não concluída. Tente novamente.';
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return 'Autenticação bloqueada temporariamente. Tente novamente '
            'mais tarde.';
      case LocalAuthExceptionCode.userRequestedFallback:
        return 'Use o PIN ou a senha do dispositivo para continuar.';
      default:
        return 'Falha na autenticação. Tente novamente.';
    }
  }
}