import 'package:dio/dio.dart';

import '../../../../app_config.dart';
import '../../../../shared/patterns/result.dart';
import '../models/place_suggestion_model.dart';

class PlacesService {
  PlacesService({Dio? dio, String? apiKey})
    : _dio = dio ?? Dio(),
      _apiKey = apiKey ?? AppConfig.googlePlacesApiKey;

  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  static const String _language = 'pt-BR';

  static const String _components = 'country:br';

  final Dio _dio;
  final String _apiKey;

  Future<Result<List<PlaceSuggestionModel>>> autocompleteAddress(
    String input,
  ) async {
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
