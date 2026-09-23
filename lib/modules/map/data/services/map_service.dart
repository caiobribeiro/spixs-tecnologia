import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../../../../app_config.dart';
import '../../../../shared/patterns/result.dart';
import '../models/geo_point_model.dart';
import '../models/place_model.dart';
import '../models/route_model.dart';

/// Map module data source.
///
/// Communicates with the Google Directions API via [Dio], decodes the
/// returned polyline with `flutter_polyline_points` and returns [Result]s
/// encapsulating success or failure.
class MapService {
  MapService({
    Dio? dio,
    String? apiKey,
  })  : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? AppConfig.googleMapsApiKey;

  static const String _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  final Dio _dio;
  final String _apiKey;

  /// Loads the places displayed on the map.
  ///
  /// Placeholder implementation until the backend is available.
  Future<Result<List<PlaceModel>>> getPlaces() async {
    try {
      return Result.ok(
        const [
          PlaceModel(
            id: 'p1',
            name: 'Spixs Tecnologia HQ',
            location: GeoPointModel(latitude: -23.5505, longitude: -46.6333),
          ),
          PlaceModel(
            id: 'p2',
            name: 'Reference Point',
            location: GeoPointModel(latitude: -23.5614, longitude: -46.6559),
          ),
        ],
      );
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  /// Requests a route between [origin] and [destination] from the Google
  /// Directions API and decodes the overview polyline.
  Future<Result<RouteModel>> getRoute({
    required GeoPointModel origin,
    required GeoPointModel destination,
  }) async {
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
        _directionsUrl,
        queryParameters: <String, dynamic>{
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': _apiKey,
        },
      );

      final data = response.data;
      if (data == null) {
        return Result.error(Exception('Empty directions response'));
      }

      final routes = data['routes'] as List<dynamic>? ?? const <dynamic>[];
      if (routes.isEmpty) {
        return Result.error(Exception('No routes found'));
      }

      final firstRoute = routes.first as Map<String, dynamic>;
      final overviewPolyline =
          (firstRoute['overview_polyline'] as Map<String, dynamic>?)?['points']
                  as String? ??
              '';

      final decodedPoints = PolylinePoints.decodePolyline(overviewPolyline)
          .map(
            (point) => GeoPointModel(
              latitude: point.latitude,
              longitude: point.longitude,
            ),
          )
          .toList();

      final legs = firstRoute['legs'] as List<dynamic>? ?? const <dynamic>[];
      final firstLeg =
          legs.isEmpty ? null : (legs.first as Map<String, dynamic>);
      final distanceMeters =
          ((firstLeg?['distance'] as Map<String, dynamic>?)?['value'] as num?)
                  ?.toDouble() ??
              0;
      final durationSeconds =
          ((firstLeg?['duration'] as Map<String, dynamic>?)?['value'] as num?)
                  ?.toInt() ??
              0;

      return Result.ok(
        RouteModel(
          origin: origin,
          destination: destination,
          polylinePoints: decodedPoints,
          distanceMeters: distanceMeters,
          durationSeconds: durationSeconds,
        ),
      );
    } on DioException catch (error) {
      return Result.error(Exception(error.message));
    } on Exception catch (error) {
      return Result.error(error);
    }
  }
}