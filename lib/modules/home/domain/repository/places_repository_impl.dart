import '../../../../shared/patterns/result.dart';
import '../../data/models/place_suggestion_model.dart';
import '../../data/services/places_service.dart';
import '../entity/place_suggestion_entity.dart';
import 'places_repository.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  PlacesRepositoryImpl(this._service);

  final PlacesService _service;

  @override
  Future<Result<List<PlaceSuggestionEntity>>> autocompleteAddress(
    String input,
  ) async {
    final result = await _service.autocompleteAddress(input);

    switch (result) {
      case Ok<List<PlaceSuggestionModel>>():
        final value = result.value;
        return Result.ok(value.map((model) => model.toEntity()).toList());
      case Error<List<PlaceSuggestionModel>>():
        final value = result;
        return Result.error(value.error);
    }
  }
}
