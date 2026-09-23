import 'package:dio/dio.dart';

import '../../../../app_config.dart';
import '../../../../shared/patterns/result.dart';
import '../models/place_suggestion_model.dart';

/// Home module data source for the Google Places Autocomplete API.
///
/// Communicates with `place/autocomplete/json` via [Dio] and returns a
/// [Result] encapsulating success or failure. The API key is injected at
/// build time through [AppConfig.googlePlacesApiKey] (`--dart-define`), so
/// it never lives in the source tree.
class PlacesService {
  PlacesService({Dio? dio, String? apiKey})
      : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? AppConfig.googlePlacesApiKey;

  /// Endpoint de autocomplete de endereços do Google Places.
  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  /// Idioma dos endereços sugeridos (UI do app é pt-BR).
  static const String _language = 'pt-BR';

  /// Restringe as sugestões ao Brasil, mercado do app de entregas.
  static const String _components = 'country:br';

  final Dio _dio;
  final String _apiKey;

  /// Autocompleta [input] com sugestões de endereços do Google Places.
  ///
  /// Retorna a lista de [PlaceSuggestionModel] ordenada como o Google
  /// retorna (relevância). `ZERO_RESULTS` não é erro: resulta em lista
  /// vazia.
  Future<Result<List<PlaceSuggestionModel>>> autocompleteAddress(
    String input,
  ) async {
    // Fail fast: chave ausente produziria REQUEST_DENIED opaco da API.
    if (_apiKey.isEmpty) {
      return Result.error(
        Exception(
          'Chave da Google Places API não configurada. Execute o app com '
          '`--dart-define-from-file=env.json` ou '
          '`--dart-define=GOOGLE_PLACES_API_KEY=<sua-chave>` (ver README.md).',
        ),
      );
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _autocompleteUrl,
        queryParameters: <String, dynamic>{
          'input': input,
          'key': _apiKey,
          'language': _language,
          'components': _components,
        },
      );

      final data = response.data;
      if (data == null) {
        return Result.error(Exception('Empty autocomplete response'));
      }

      final status = data['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        return Result.error(Exception('Places API error: $status'));
      }

      final predictions =
          data['predictions'] as List<dynamic>? ?? const <dynamic>[];
      return Result.ok(
        predictions
            .whereType<Map<String, dynamic>>()
            .map(PlaceSuggestionModel.fromMap)
            .toList(),
      );
    } on DioException catch (error) {
      return Result.error(Exception(error.message));
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}