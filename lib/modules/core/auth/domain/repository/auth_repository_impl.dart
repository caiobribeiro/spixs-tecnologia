import 'package:flutter/foundation.dart';

import '../../../../../shared/patterns/result.dart';
import '../../data/services/auth_service.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._service);

  final AuthService _service;

  final ValueNotifier<bool> _isAuthenticated = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get isAuthenticated => _isAuthenticated;

  @override
  Future<Result<bool>> authenticate() async {
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
