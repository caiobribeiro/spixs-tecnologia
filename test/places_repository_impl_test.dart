// Testes do PlacesRepositoryImpl: conversão Model → Entity e propagação de
// erros, com um PlacesService fake (sem rede).

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/home/data/models/place_suggestion_model.dart';
import 'package:spixs_tecnologia/modules/home/data/services/places_service.dart';
import 'package:spixs_tecnologia/modules/home/domain/entity/place_suggestion_entity.dart';
import 'package:spixs_tecnologia/modules/home/domain/repository/places_repository_impl.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

/// Fake que evita o Dio real: responde com um Result pré-determinado.
class _FakePlacesService extends PlacesService {
  _FakePlacesService(this._result) : super(apiKey: '');

  final Future<Result<List<PlaceSuggestionModel>>> Function(String input)
      _result;

  @override
  Future<Result<List<PlaceSuggestionModel>>> autocompleteAddress(
    String input,
  ) {
    return _result(input);
  }
}

void main() {
  const models = [
    PlaceSuggestionModel(
      placeId: 'ChIJ1',
      description: 'Av. Paulista, 1000 - Bela Vista, São Paulo - SP, Brasil',
      mainText: 'Av. Paulista, 1000',
      secondaryText: 'Bela Vista, São Paulo - SP, Brasil',
    ),
  ];

  group('PlacesRepositoryImpl.autocompleteAddress', () {
    test('converte Models em Entities preservando os campos', () async {
      final repository = PlacesRepositoryImpl(
        _FakePlacesService((input) async {
          expect(input, 'Av Paulista');
          return Result.ok(models);
        }),
      );

      final result = await repository.autocompleteAddress('Av Paulista');

      switch (result) {
        case Ok<List<PlaceSuggestionEntity>>():
          final suggestions = result.value;
          expect(suggestions, hasLength(1));
          expect(suggestions.first.placeId, 'ChIJ1');
          expect(suggestions.first.mainText, 'Av. Paulista, 1000');
          expect(suggestions.first.secondaryText,
              'Bela Vista, São Paulo - SP, Brasil');
        case Error<List<PlaceSuggestionEntity>>():
          fail('esperava Ok, recebi erro: ${result.error}');
      }
    });

    test('propaga erro do service como Result.error', () async {
      final failure = Exception('Places API error: REQUEST_DENIED');
      final repository = PlacesRepositoryImpl(
        _FakePlacesService((input) async => Result.error(failure)),
      );

      final result = await repository.autocompleteAddress('Av Paulista');

      expect(result, isA<Error<List<PlaceSuggestionEntity>>>());
      expect(
        (result as Error<List<PlaceSuggestionEntity>>).error,
        same(failure),
      );
    });

    test('propaga lista vazia sem erro', () async {
      final repository = PlacesRepositoryImpl(
        _FakePlacesService((input) async => Result.ok(const [])),
      );

      final result = await repository.autocompleteAddress('xyzxyz');

      expect(result, isA<Ok<List<PlaceSuggestionEntity>>>());
      expect((result as Ok<List<PlaceSuggestionEntity>>).value, isEmpty);
    });
  });
}