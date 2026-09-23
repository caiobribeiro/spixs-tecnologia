import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../../../../app_config.dart';
import '../../../../shared/patterns/result.dart';
import '../models/geo_point_model.dart';
import '../models/place_model.dart';
import '../models/route_model.dart';
import '../models/route_waypoint_model.dart';

/// Map module data source.
///
/// Communicates with the Google **Routes API** (`computeRoutes`, v2) via
/// [Dio], decodes the returned polyline with `flutter_polyline_points` and
/// returns [Result]s encapsulating success or failure.
class MapService {
  MapService({
    Dio? dio,
    String? apiKey,
  })  : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? AppConfig.googleMapsApiKey;

  /// Endpoint de rotas otimizadas da Google Routes API (v2).
  static const String _computeRoutesUrl =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  /// Field mask obrigatória da Routes API — sem ela a API responde 400.
  ///
  /// Pede as informações que a tela do mapa consome: totais, geometria
  /// (polyline), legs (waypoints resolvidos) e a ordem otimizada.
  static const String _fieldMask =
      'routes.distanceMeters,routes.duration,routes.polyline,'
      'routes.legs,routes.optimizedIntermediateWaypointIndex';

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

  /// Computes a route that visits [addresses] in order, asking the Routes
  /// API to **optimize the intermediate waypoints**
  /// (`optimizeWaypointOrder: true`).
  ///
  /// When [origin] (a coordenada do usuário) é informado, **todos** os
  /// [addresses] são pontos de parada — o último é o destino e os demais
  /// intermediários — e a origem vira a localização do usuário. Sem [origin],
  /// o primeiro endereço é a origem e o último o destino. O [RouteModel]
  /// devolvido carrega os waypoints na ordem da rota, a polyline decodificada,
  /// os totais e a [RouteModel.userOrigin] quando aplicável.
  Future<Result<RouteModel>> computeRoute(
    List<String> addresses, {
    GeoPointModel? origin,
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

    // Com origem do usuário, todos os endereços do formulário viram paradas
    // (destino = último, intermediários = demais). Sem ela, o primeiro
    // endereço é a origem e os demais são as paradas.
    final stops =
        hasUserOrigin ? addresses : addresses.sublist(1);
    // Rótulos de fallback alinhados aos waypoints (origem do usuário + paradas)
    // quando a resposta da API vier sem endereço resolvido em alguma leg.
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

  /// Waypoints na ordem em que a rota os visita, derivados das `legs` da
  /// resposta: cada leg começa no waypoint *i* e termina no waypoint *i+1*
  /// — já na ordem otimizada aplicada pela API
  /// (`optimizeWaypointOrder: true`).
  List<RouteWaypointModel> _orderedWaypoints(
    Map<String, dynamic> route,
    List<String> requested,
  ) {
    final legs = route['legs'] as List<dynamic>? ?? const <dynamic>[];
    if (legs.isEmpty) {
      // Resposta sem legs: mantém a ordem solicitada no formulário.
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
        final fallbackEnd =
            i + 1 < requested.length ? requested[i + 1] : requested.last;
        waypoints.add(
          _legEndpoint(leg, start: false, fallbackAddress: fallbackEnd),
        );
      }
    }
    return waypoints;
  }

  /// Extrai endereço + localização de uma ponta (início ou fim) de uma leg.
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

  /// Converte uma duração da Routes API para segundos: formato curto
  /// ("1628s") ou ISO-8601 ("PT27M8S" / "PT1H5M30S").
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