import 'package:flutter/foundation.dart';

import '../../../core/auth/domain/auth_failure.dart';
import '../../../core/auth/domain/repository/auth_repository.dart';
import '../../../../shared/patterns/command.dart';
import '../../../../shared/patterns/result.dart';
import '../../domain/entity/home_summary_entity.dart';
import '../../domain/repository/home_repository.dart';

class HomeViewmodel extends ChangeNotifier {
  HomeViewmodel(this._repository, this._authRepository);

  final HomeRepository _repository;
  final AuthRepository _authRepository;

  late final getSummaryCommand = Command0<HomeSummaryEntity>(
    _repository.getSummary,
  );

  /// Native authentication gate: biometria, senha, PIN ou padrão do
  /// dispositivo (Android/iOS).
  late final authenticateCommand = Command0<bool>(_authRepository.authenticate);

  /// Whether the user has already passed the native authentication gate.
  ValueListenable<bool> get isAuthenticated => _authRepository.isAuthenticated;

  /// Human-readable message for the latest authentication failure, if any.
  String? get authenticationError {
    final result = authenticateCommand.result;
    switch (result) {
      case Error(error: final error):
        if (error is AuthFailure) {
          return error.message;
        }
        return 'Falha na autenticação. Tente novamente.';
      case Ok(value: final value):
        if (!value) {
          return 'Autenticação não concluída. Tente novamente.';
        }
        return null;
      case null:
        return null;
    }
  }

  /// The latest summary loaded by [getSummaryCommand], if any.
  HomeSummaryEntity? get summary {
    final result = getSummaryCommand.result;
    if (result is Ok<HomeSummaryEntity>) {
      return result.value;
    }
    return null;
  }

  /// Runs the native authentication gate.
  Future<void> authenticate() => authenticateCommand.execute();

  /// Loads the connection summary for the home screen.
  Future<void> load() => getSummaryCommand.execute();
}
