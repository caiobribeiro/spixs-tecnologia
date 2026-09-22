import '../../../../shared/patterns/result.dart';
import '../entity/home_summary_entity.dart';

/// Contract for the home dashboard data source.
///
/// Declares the operations available to the presentation layer. The
/// concrete implementation lives in the same layer and owns the single
/// source of truth for the module data.
abstract interface class HomeRepository {
  /// Loads the current connection summary shown on the home screen.
  Future<Result<HomeSummaryEntity>> getSummary();
}