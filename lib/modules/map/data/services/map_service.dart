import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../../../../app_config.dart';
import '../../../../shared/patterns/result.dart';
import '../models/geo_point_model.dart';
import '../models/place_model.dart';
import '../models/route_model.dart';
import '../models/route_waypoint_model.dart';

class MapService {
  MapService({Dio? dio, String? apiKey})
    : _dio = dio ?? Dio(),
      _apiKey = apiKey ?? AppConfig.googleMapsApiKey;

  static const String _computeRoutesUrl =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  static const String _fieldMask =
      'routes.distanceMeters,routes.duration,routes.polyline,'
      'routes.legs,routes.optimizedIntermediateWaypointIndex';

  final Dio _dio;
  final String _apiKey;

  Future<Result<List<PlaceModel>>> getPlaces() async {
    try {
      return Result.ok(const [
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
      ]);
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<RouteModel>> computeRoute(
    List<String> addresses, {
    GeoPointModel? origin,
  }) async {
    if (_apiKey.isEmpty) {
      return Result.error(
        Exception(
          'Chave da Google Maps API não configurada. Execute o app com '
          '`--dart-define-from-file=env.json` ou '
          '`--dart-define=GOOGLE_MAPS_API_KEY=<sua-chave>` (ver README.md).',
        ),
      );
    }
    final hasUserOrigin = origin != null;
    if (!hasUserOrigin && addresses.length < 2) {
      return Result.error(
        Exception('A rota precisa de origem e destino (mínimo 2 endereços).'),
      );
    }
    if (hasUserOrigin && addresses.isEmpty) {
      return Result.error(
        Exception('A rota precisa de pelo menos um endereço de destino.'),
      );
    }

    final stops = hasUserOrigin ? addresses : addresses.sublist(1);

    final requestedLabels = hasUserOrigin
        ? <String>['Sua localização', ...stops]
        : addresses;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _computeRoutesUrl,
        options: Options(
          headers: <String, dynamic>{
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask': _fieldMask,
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
        ),
        data: <String, dynamic>{
          'origin': hasUserOrigin
              ? <String, dynamic>{
                  'location': <String, dynamic>{
                    'latLng': <String, dynamic>{
                      'latitude': origin.latitude,
                      'longitude': origin.longitude,
                    },
                  },
                }
              : <String, dynamic>{'address': addresses.first},
          'destination': <String, dynamic>{'address': stops.last},
          'intermediates': <Map<String, dynamic>>[
            for (final address in stops.sublist(0, stops.length - 1))
              <String, dynamic>{'address': address},
          ],
          'travelMode': 'DRIVE',
          'optimizeWaypointOrder': true,
        },
      );

      final data = response.data;
      if (data == null) {
        return Result.error(Exception('Empty routes response'));
      }

      final routes = data['routes'] as List<dynamic>? ?? const <dynamic>[];
      if (routes.isEmpty) {
        return Result.error(Exception('No routes found'));
      }

      final firstRoute = routes.first as Map<String, dynamic>;
      final overviewPolyline =
          ((firstRoute['polyline'] as Map<String, dynamic>?)?['encodedPolyline']
              as String?) ??
          '';
      final decodedPoints = PolylinePoints.decodePolyline(overviewPolyline)
          .map(
            (point) => GeoPointModel(
              latitude: point.latitude,
              longitude: point.longitude,
            ),
          )
          .toList();

      return Result.ok(
        RouteModel(
          waypoints: _orderedWaypoints(firstRoute, requestedLabels),
          polylinePoints: decodedPoints,
          distanceMeters:
              (firstRoute['distanceMeters'] as num?)?.toDouble() ?? 0,
          durationSeconds: _parseDurationSeconds(firstRoute['duration']),
          optimizedIntermediateWaypointIndex:
              (firstRoute['optimizedIntermediateWaypointIndex']
                      as List<dynamic>?)
                  ?.map((index) => (index as num).toInt())
                  .toList() ??
              const <int>[],
          userOrigin: origin,
        ),
      );
    } on DioException catch (error) {
      return Result.error(Exception(error.message));
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  List<RouteWaypointModel> _orderedWaypoints(
    Map<String, dynamic> route,
    List<String> requested,
  ) {
    final legs = route['legs'] as List<dynamic>? ?? const <dynamic>[];
    if (legs.isEmpty) {
      return [
        for (final address in requested)
          RouteWaypointModel(
            address: address,
            location: const GeoPointModel(latitude: 0, longitude: 0),
          ),
      ];
    }

    final waypoints = <RouteWaypointModel>[];
    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i] as Map<String, dynamic>;
      final fallbackStart = i < requested.length ? requested[i] : '';
      waypoints.add(
        _legEndpoint(leg, start: true, fallbackAddress: fallbackStart),
      );
      if (i == legs.length - 1) {
        final fallbackEnd = i + 1 < requested.length
            ? requested[i + 1]
            : requested.last;
        waypoints.add(
          _legEndpoint(leg, start: false, fallbackAddress: fallbackEnd),
        );
      }
    }
    return waypoints;
  }

  RouteWaypointModel _legEndpoint(
    Map<String, dynamic> leg, {
    required bool start,
    required String fallbackAddress,
  }) {
    final locationField = start ? 'startLocation' : 'endLocation';
    final addressField = start ? 'startAddress' : 'endAddress';

    final resolvedAddress = leg[addressField] as String?;
    final latLng =
        (leg[locationField] as Map<String, dynamic>?)?['latLng']
            as Map<String, dynamic>?;

    return RouteWaypointModel(
      address: (resolvedAddress?.trim().isNotEmpty ?? false)
          ? resolvedAddress!
          : fallbackAddress,
      location: GeoPointModel(
        latitude: (latLng?['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (latLng?['longitude'] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  static int _parseDurationSeconds(dynamic duration) {
    if (duration is! String || duration.isEmpty) {
      return 0;
    }

    final iso = RegExp(r'^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?$');
    final isoMatch = iso.firstMatch(duration);
    if (isoMatch != null) {
      final hours = int.tryParse(isoMatch.group(1) ?? '') ?? 0;
      final minutes = int.tryParse(isoMatch.group(2) ?? '') ?? 0;
      final seconds = (double.tryParse(isoMatch.group(3) ?? '0') ?? 0).round();
      return hours * 3600 + minutes * 60 + seconds;
    }

    final short = RegExp(r'^(\d+)s$').firstMatch(duration);
    return int.tryParse(short?.group(1) ?? '0') ?? 0;
  }
}
