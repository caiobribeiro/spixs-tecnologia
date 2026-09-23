import 'package:dio/dio.dart';

import '../../../../app_config.dart';
import '../../../../shared/patterns/result.dart';
import '../models/geo_point_model.dart';

/// Map module data source for the Google **Geocoding API**.
///
/// Resolves a typed address (from the route form) to its geographic
/// coordinates. The map repository uses these coordinates to run the
/// **distance check** that orders the stops from the closest to the
/// farthest from the user before computing the route. The API key is
/// injected at build time through [AppConfig.googleMapsApiKey]
/// (`--dart-define`), so it never lives in the source tree.
class GeocodingService {
  GeocodingService({Dio? dio, String? apiKey})
      : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? AppConfig.googleMapsApiKey;

  /// Endpoint de geocoding do Google Maps.
  static const String _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  /// Idioma dos resultados (UI do app é pt-BR).
  static const String _language = 'pt-BR';

  /// Restringe a busca ao Brasil, mercado do app de entregas.
  static const String _components = 'country:br';

  final Dio _dio;
  final String _apiKey;

  /// Resolves [address] to its coordinates via the Google Geocoding API.
  ///
  /// Returns the coordinates of the most relevant result. Zero results,
  /// API errors and missing keys are returned as [Result.error] so the
  /// caller can decide the recovery (fail fast — the route depends on the
  /// distance check).
  Future<Result<GeoPointModel>> geocodeAddress(String address) async {
    // Fail fast: chave ausente produziria REQUEST_DENIED opaco da API.
    if (_apiKey.isEmpty) {
      return Result.error(
        Exception(
          'Chave da Google Maps API não configurada. Execute o app com '
          '`--dart-define-from-file=env.json` ou '
          '`--dart-define=GOOGLE_MAPS_API_KEY=<sua-chave>` (ver README.md).',
        ),
      );
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _geocodeUrl,
        queryParameters: <String, dynamic>{
          'address': address,
          'key': _apiKey,
          'language': _language,
          'components': _components,
        },
      );

      final data = response.data;
      if (data == null) {
        return Result.error(Exception('Empty geocoding response'));
      }

      final status = data['status'] as String?;
      if (status != 'OK') {
        return Result.error(Exception('Geocoding API error: $status'));
      }

      final results =
          data['results'] as List<dynamic>? ?? const <dynamic>[];
      if (results.isEmpty) {
        return Result.error(
          Exception('Endereço não encontrado pelo geocoding: $address'),
        );
      }

      final geometry =
          (results.first as Map<String, dynamic>)['geometry']
              as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      if (location == null) {
        return Result.error(
          Exception('Sem coordenadas para o endereço: $address'),
        );
      }

      return Result.ok(
        GeoPointModel(
          latitude: (location['lat'] as num).toDouble(),
          longitude: (location['lng'] as num).toDouble(),
        ),
      );
    } on DioException catch (error) {
      return Result.error(Exception(error.message));
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}