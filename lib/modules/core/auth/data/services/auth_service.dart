import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../../shared/patterns/result.dart';
import '../../domain/auth_failure.dart';

class AuthService {
  AuthService({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  bool get isSupportedPlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<Result<bool>> authenticate() async {
    if (!isSupportedPlatform) {
      return Result.ok(false);
    }

    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Autentique-se para acessar o app',

        biometricOnly: false,

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
