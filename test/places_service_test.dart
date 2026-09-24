// Testes do PlacesService: parsing e tratamento de resultados da Google
// Places Autocomplete API, com um adapter HTTP simulado (sem rede).

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/home/data/models/place_suggestion_model.dart';
import 'package:spixs_tecnologia/modules/home/data/services/places_service.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

/// Adapter de Http que responde com um payload fixo por chamada.
class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

PlacesService _serviceReturning(
  Map<String, dynamic> payload, {
  int statusCode = 200,
}) {
  final adapter = _FakeHttpClientAdapter((options) async {
    return ResponseBody.fromString(
      jsonEncode(payload),
      statusCode,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  });
  return PlacesService(dio: Dio()..httpClientAdapter = adapter, apiKey: 'test-key');
}

void main() {
  group('PlacesService.autocompleteAddress', () {
    test('envia input, key, idioma e país na query string', () async {
      Map<String, dynamic>? capturedQuery;
      final adapter = _FakeHttpClientAdapter((options) async {
        capturedQuery = options.queryParameters;
        return ResponseBody.fromString(
          jsonEncode({'status': 'OK', 'predictions': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });
      final service = PlacesService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: 'test-key',
      );

      await service.autocompleteAddress('Av Paulista');

      expect(capturedQuery, isNotNull);
      expect(capturedQuery!['input'], 'Av Paulista');
      expect(capturedQuery!['key'], 'test-key');
      expect(capturedQuery!['language'], 'pt-BR');
      expect(capturedQuery!['components'], 'country:br');
    });

    test('parseia predictions em PlaceSuggestionModel', () async {
      final service = _serviceReturning({
        'status': 'OK',
        'predictions': [
          {
            'place_id': 'ChIJ1',
            'description':
                'Av. Paulista, 1000 - Bela Vista, São Paulo - SP, Brasil',
            'structured_formatting': {
              'main_text': 'Av. Paulista, 1000',
              'secondary_text': 'Bela Vista, São Paulo - SP, Brasil',
            },
          },
          {
            'place_id': 'ChIJ2',
            'description':
                'Av. Paulista, 1578 - Bela Vista, São Paulo - SP, Brasil',
            'structured_formatting': {
              'main_text': 'Av. Paulista, 1578',
              'secondary_text': 'Bela Vista, São Paulo - SP, Brasil',
            },
          },
        ],
      });

      final result = await service.autocompleteAddress('Av Paulista');

      switch (result) {
        case Ok<List<PlaceSuggestionModel>>():
          final suggestions = result.value;
          expect(suggestions, hasLength(2));
          expect(suggestions.first.placeId, 'ChIJ1');
          expect(suggestions.first.mainText, 'Av. Paulista, 1000');
          expect(
            suggestions.first.secondaryText,
            'Bela Vista, São Paulo - SP, Brasil',
          );
          expect(suggestions.first.description, contains('Av. Paulista, 1000'));
        case Error<List<PlaceSuggestionModel>>():
          fail('esperava Ok, recebi erro: ${result.error}');
      }
    });

    test('structured_formatting ausente faz fallback para description', () async {
      final service = _serviceReturning({
        'status': 'OK',
        'predictions': [
          {
            'place_id': 'ChIJ1',
            'description': 'Rua Sem Formatação, São Paulo - SP, Brasil',
          },
        ],
      });

      final result = await service.autocompleteAddress('Rua Sem');

      switch (result) {
        case Ok<List<PlaceSuggestionModel>>():
          expect(result.value.single.mainText,
              'Rua Sem Formatação, São Paulo - SP, Brasil');
          expect(result.value.single.secondaryText, '');
        case Error<List<PlaceSuggestionModel>>():
          fail('esperava Ok, recebi erro: ${result.error}');
      }
    });

    test('chave vazia falha rápido com erro acionável (sem rede)', () async {
      final adapter = _FakeHttpClientAdapter((options) async {
        fail('nenhuma requisição deve ser feita com chave ausente');
      });
      final service = PlacesService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: '',
      );

      final result = await service.autocompleteAddress('Av Paulista');

      expect(result, isA<Error<List<PlaceSuggestionModel>>>());
      expect(
        (result as Error<List<PlaceSuggestionModel>>).error.toString(),
        contains('GOOGLE_PLACES_API_KEY'),
      );
    });

    test('ZERO_RESULTS não é erro: retorna lista vazia', () async {
      final service =
          _serviceReturning({'status': 'ZERO_RESULTS', 'predictions': []});

      final result = await service.autocompleteAddress('xyzxyz');

      switch (result) {
        case Ok<List<PlaceSuggestionModel>>():
          expect(result.value, isEmpty);
        case Error<List<PlaceSuggestionModel>>():
          fail('esperava Ok vazio, recebi erro: ${result.error}');
      }
    });

    test('status de erro da API vira Result.error', () async {
      final service = _serviceReturning({
        'status': 'REQUEST_DENIED',
        'error_message': 'The provided API key is invalid.',
      });

      final result = await service.autocompleteAddress('Av Paulista');

      expect(result, isA<Error<List<PlaceSuggestionModel>>>());
    });

    test('DioException vira Result.error com a mensagem da exceção', () async {
      final adapter = _FakeHttpClientAdapter((options) async {
        throw DioException(requestOptions: options, message: 'no internet');
      });
      final service = PlacesService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: 'test-key',
      );

      final result = await service.autocompleteAddress('Av Paulista');

      expect(result, isA<Error<List<PlaceSuggestionModel>>>());
      expect(
        (result as Error<List<PlaceSuggestionModel>>).error.toString(),
        contains('no internet'),
      );
    });

    test('resposta vazia vira Result.error', () async {
      final adapter = _FakeHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          '',
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });
      final service = PlacesService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: 'test-key',
      );

      final result = await service.autocompleteAddress('Av Paulista');

      expect(result, isA<Error<List<PlaceSuggestionModel>>>());
    });
  });
}