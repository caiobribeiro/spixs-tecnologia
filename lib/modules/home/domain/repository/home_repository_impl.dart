import '../../../../shared/patterns/result.dart';
import '../../data/models/home_summary_model.dart';
import '../../data/services/home_service.dart';
import '../entity/home_summary_entity.dart';
import 'home_repository.dart';

/// Concrete [HomeRepository].
///
/// Delegates data access to the [HomeService] (data layer) and converts
/// [HomeSummaryModel] into [HomeSummaryEntity].
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._service);

  final HomeService _service;

  @override
  Future<Result<HomeSummaryEntity>> getSummary() async {
    final result = await _service.getSummary();

    switch (result) {
      case Ok<HomeSummaryModel>():
        final value = result.value;
        return Result.ok(value.toEntity());
      case Error<HomeSummaryModel>():
        final value = result;
        return Result.error(value.error);
    }
  }
}