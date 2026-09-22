import 'package:flutter/foundation.dart';

import '../../../../../shared/patterns/result.dart';
import '../../data/services/auth_service.dart';
import 'auth_repository.dart';

/// Concrete [AuthRepository].
///
/// Owns the single source of truth for the authentication state
/// ([isAuthenticated]) and delegates the native prompt to the [AuthService]
/// (data layer).
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._service);

  final AuthService _service;

  final ValueNotifier<bool> _isAuthenticated = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get isAuthenticated => _isAuthenticated;

  @override
  Future<Result<bool>> authenticate() async {
    // O gate nativo (local_auth) só funciona em Android/iOS. Nas demais
    // plataformas o acesso é liberado para não quebrar desenvolvimento,
    // testes e builds web/desktop.
    if (!_service.isSupportedPlatform) {
      _isAuthenticated.value = true;
      return Result.ok(true);
    }

    final result = await _service.authenticate();

    switch (result) {
      case Ok<bool>():
        final value = result.value;
        _isAuthenticated.value = value;
        return Result.ok(value);
      case Error<bool>():
        final value = result;
        return Result.error(value.error);
    }
  }
}