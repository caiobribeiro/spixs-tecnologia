import '../../../../shared/patterns/result.dart';
import '../entity/place_suggestion_entity.dart';

abstract interface class PlacesRepository {
  Future<Result<List<PlaceSuggestionEntity>>> autocompleteAddress(String input);
}
