import 'package:flutter/foundation.dart';

import '../../../../../shared/patterns/result.dart';

abstract interface class AuthRepository {
  ValueListenable<bool> get isAuthenticated;

  Future<Result<bool>> authenticate();
}
