import 'package:flutter/foundation.dart';

import 'package:spixs_tecnologia/modules/core/auth/domain/repository/auth_repository.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

/// [AuthRepository] fake que devolve sempre [result] e reflete o valor de
/// sucesso no estado de autenticação.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._result);

  final Result<bool> _result;
  final ValueNotifier<bool> _isAuthenticated = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get isAuthenticated => _isAuthenticated;

  @override
  Future<Result<bool>> authenticate() async {
    final result = _result;
    if (result is Ok<bool>) {
      _isAuthenticated.value = result.value;
    }
    return result;
  }
}