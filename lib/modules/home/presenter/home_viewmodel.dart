import 'package:flutter/foundation.dart';

import '../../../../shared/patterns/command.dart';
import '../../../../shared/patterns/result.dart';
import '../domain/entity/home_summary_entity.dart';
import '../domain/repository/home_repository.dart';

/// Manages the state and logic of the home screen.
///
/// Exposes [Command]s to perform actions and reads data through the
/// [HomeRepository] contract. It never depends on the repository
/// implementation directly.
class HomeViewmodel extends ChangeNotifier {
  HomeViewmodel(this._repository);

  final HomeRepository _repository;

  late final getSummaryCommand = Command0<HomeSummaryEntity>(
    _repository.getSummary,
  );

  /// The latest summary loaded by [getSummaryCommand], if any.
  HomeSummaryEntity? get summary {
    final result = getSummaryCommand.result;
    if (result is Ok<HomeSummaryEntity>) {
      return result.value;
    }
    return null;
  }

  /// Loads the connection summary for the home screen.
  Future<void> load() => getSummaryCommand.execute();
}