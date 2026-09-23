import '../../../../shared/patterns/result.dart';
import '../entity/home_summary_entity.dart';

abstract interface class HomeRepository {
  Future<Result<HomeSummaryEntity>> getSummary();
}
