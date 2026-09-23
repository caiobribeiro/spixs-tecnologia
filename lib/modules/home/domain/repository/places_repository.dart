import '../../../../shared/patterns/result.dart';
import '../entity/place_suggestion_entity.dart';

/// Contract for the address autocomplete data source.
///
/// Declares the operations available to the presentation layer. The
/// concrete implementation lives in the same layer and owns the single
/// source of truth for the module data.
abstract interface class PlacesRepository {
  /// Autocompletes [input] with Google Places address suggestions.
  Future<Result<List<PlaceSuggestionEntity>>> autocompleteAddress(
    String input,
  );
}