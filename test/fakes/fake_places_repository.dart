import 'package:spixs_tecnologia/modules/home/domain/entity/place_suggestion_entity.dart';
import 'package:spixs_tecnologia/modules/home/domain/repository/places_repository.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

/// Deterministic [PlacesRepository] for tests: returns canned suggestions
/// or a fixed error, never touching the network.
class FakePlacesRepository implements PlacesRepository {
  FakePlacesRepository({
    this.suggestions = const [],
    this.error,
  });

  final List<PlaceSuggestionEntity> suggestions;
  final Exception? error;

  /// Número de vezes que [autocompleteAddress] foi chamado.
  int calls = 0;

  /// Última consulta recebida, para asserções nos testes.
  String? lastInput;

  @override
  Future<Result<List<PlaceSuggestionEntity>>> autocompleteAddress(
    String input,
  ) async {
    calls++;
    lastInput = input;
    if (error != null) {
      return Result.error(error!);
    }
    return Result.ok(List.of(suggestions));
  }
}