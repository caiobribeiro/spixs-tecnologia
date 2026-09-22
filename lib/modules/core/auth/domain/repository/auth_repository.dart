import 'package:flutter/foundation.dart';

import '../../../../../shared/patterns/result.dart';

/// Contract for the native authentication gate.
///
/// The concrete implementation owns the single source of truth for the
/// authentication state ([isAuthenticated]).
abstract interface class AuthRepository {
  /// Whether the user has already authenticated in the current session.
  ValueListenable<bool> get isAuthenticated;

  /// Runs the native authentication flow.
  ///
  /// Returns `true` when the user authenticates successfully (biometria,
  /// senha, PIN ou padrão do dispositivo).
  Future<Result<bool>> authenticate();
}