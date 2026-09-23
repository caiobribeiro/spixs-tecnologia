// Testes do MapService (Google Routes API v2): corpo/headers da requisição
// e parsing da resposta de `computeRoutes`, com um adapter HTTP simulado.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/data/models/geo_point_model.dart';
import 'package:spixs_tecnologia/modules/map/data/models/route_model.dart';
import 'package:spixs_tecnologia/modules/map/data/services/map_service.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

/// Adapter de Http que responde com um payload fixo por chamada.
class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
  ) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options, requestStream);
  }

  @override
  void close({bool force = false}) {}
}

/// Lê e decodifica o corpo JSON de um POST (enviado via request stream).
Future<Map<String, dynamic>?> _readJsonBody(Stream<Uint8List>? stream) async {
  if (stream == null) {
    return null;
  }
  final bytes = <int>[];
  await for (final chunk in stream) {
    bytes.addAll(chunk);
  }
  if (bytes.isEmpty) {
    return null;
  }
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

MapService _serviceReturning(
  Map<String, dynamic> payload, {
  String apiKey = 'test-key',
  int statusCode = 200,
}) {
  final adapter = _FakeHttpClientAdapter((options, stream) async {
    return ResponseBody.fromString(
      jsonEncode(payload),
      statusCode,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  });
  return MapService(dio: Dio()..httpClientAdapter = adapter, apiKey: apiKey);
}

/// Payload mínimo mas realista da Routes API para 4 endereços: origem A,
/// destino D e intermediários B/C — a API respondeu a ordem otimizada C,B.
Map<String, dynamic> _sampleRoutesPayload({
  String duration = '1628s',
}) {
  return {
    'routes': [
      {
        'distanceMeters': 12500,
        'duration': duration,
        'polyline': {
          'encodedPolyline': r'_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        },
        'optimizedIntermediateWaypointIndex': [1, 0],
        'legs': [
          {
            'startAddress': 'Av. A',
            'startLocation': {
              'latLng': {'latitude': -23.1, 'longitude': -46.1},
            },
            'endAddress': 'Rua C',
            'endLocation': {
              'latLng': {'latitude': -23.2, 'longitude': -46.2},
            },
          },
          {
            'startAddress': 'Rua C',
            'startLocation': {
              'latLng': {'latitude': -23.2, 'longitude': -46.2},
            },
            'endAddress': 'Rua B',
            'endLocation': {
              'latLng': {'latitude': -23.3, 'longitude': -46.3},
            },
          },
          {
            'startAddress': 'Rua B',
            'startLocation': {
              'latLng': {'latitude': -23.3, 'longitude': -46.3},
            },
            'endAddress': 'Av. D',
            'endLocation': {
              'latLng': {'latitude': -23.4, 'longitude': -46.4},
            },
          },
        ],
      },
    ],
  };
}

/// Payload com origem = localização do usuário e 4 paradas (Av. A → Av. D):
/// a API recebeu a origem como latLng e todos os endereços viram stops.
Map<String, dynamic> _userOriginRoutesPayload() {
  return {
    'routes': [
      {
        'distanceMeters': 12500,
        'duration': '1628s',
        'polyline': {
          'encodedPolyline': r'_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        },
        'optimizedIntermediateWaypointIndex': [0, 1, 2],
        'legs': [
          {
            'startAddress': 'Sua localização',
            'startLocation': {
              'latLng': {'latitude': -23.5505, 'longitude': -46.6333},
            },
            'endAddress': 'Av. A',
            'endLocation': {
              'latLng': {'latitude': -23.1, 'longitude': -46.1},
            },
          },
          {
            'startAddress': 'Av. A',
            'startLocation': {
              'latLng': {'latitude': -23.1, 'longitude': -46.1},
            },
            'endAddress': 'Rua B',
            'endLocation': {
              'latLng': {'latitude': -23.2, 'longitude': -46.2},
            },
          },
          {
            'startAddress': 'Rua B',
            'startLocation': {
              'latLng': {'latitude': -23.2, 'longitude': -46.2},
            },
            'endAddress': 'Rua C',
            'endLocation': {
              'latLng': {'latitude': -23.3, 'longitude': -46.3},
            },
          },
          {
            'startAddress': 'Rua C',
            'startLocation': {
              'latLng': {'latitude': -23.3, 'longitude': -46.3},
            },
            'endAddress': 'Av. D',
            'endLocation': {
              'latLng': {'latitude': -23.4, 'longitude': -46.4},
            },
          },
        ],
      },
    ],
  };
}

void main() {
  const addresses = ['Av. A', 'Rua B', 'Rua C', 'Av. D'];

  group('MapService.computeRoute', () {
    test('POST em computeRoutes com key, field mask e optimizeWaypointOrder',
        () async {
      RequestOptions? captured;
      Map<String, dynamic>? capturedBody;
      final adapter = _FakeHttpClientAdapter((options, stream) async {
        captured = options;
        capturedBody = await _readJsonBody(stream);
        return ResponseBody.fromString(
          jsonEncode(_sampleRoutesPayload()),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });
      final service = MapService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: 'test-key',
      );

      await service.computeRoute(addresses);

      expect(captured, isNotNull);
      expect(captured!.method, 'POST');
      expect(
        captured!.uri.toString(),
        contains('directions/v2:computeRoutes'),
      );
      // Autenticação e field mask obrigatória da Routes API.
      expect(captured!.headers['X-Goog-Api-Key'], 'test-key');
      expect(captured!.headers[Headers.contentTypeHeader],
          Headers.jsonContentType);
      final fieldMask = captured!.headers['X-Goog-FieldMask'] as String;
      expect(fieldMask, contains('routes.distanceMeters'));
      expect(fieldMask, contains('routes.duration'));
      expect(fieldMask, contains('routes.polyline'));
      expect(fieldMask, contains('routes.legs'));
      expect(fieldMask, contains('routes.optimizedIntermediateWaypointIndex'));

      // Corpo: origem, destino, intermediários e otimização de paradas.
      expect(capturedBody!['origin'], {'address': 'Av. A'});
      expect(capturedBody!['destination'], {'address': 'Av. D'});
      expect(capturedBody!['intermediates'], [
        {'address': 'Rua B'},
        {'address': 'Rua C'},
      ]);
      expect(capturedBody!['travelMode'], 'DRIVE');
      expect(capturedBody!['optimizeWaypointOrder'], isTrue);
    });

    test('envia apenas origem/destino (sem intermediates) com 2 endereços',
        () async {
      Map<String, dynamic>? capturedBody;
      final adapter = _FakeHttpClientAdapter((options, stream) async {
        capturedBody = await _readJsonBody(stream);
        return ResponseBody.fromString(
          jsonEncode({
            'routes': [
              {
                'distanceMeters': 100,
                'duration': '10s',
                'polyline': {'encodedPolyline': ''},
                'legs': [],
              },
            ],
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });
      final service = MapService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: 'test-key',
      );

      await service.computeRoute(['Av. A', 'Av. D']);

      expect(capturedBody!['origin'], {'address': 'Av. A'});
      expect(capturedBody!['destination'], {'address': 'Av. D'});
      expect(capturedBody!['intermediates'], isEmpty);
      expect(capturedBody!['optimizeWaypointOrder'], isTrue);
    });

    test(
        'com localização do usuário, origem vira latLng e todos os endereços '
        'viram paradas (otimizadas)', () async {
      Map<String, dynamic>? capturedBody;
      final adapter = _FakeHttpClientAdapter((options, stream) async {
        capturedBody = await _readJsonBody(stream);
        return ResponseBody.fromString(
          jsonEncode(_userOriginRoutesPayload()),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });
      final service = MapService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: 'test-key',
      );

      await service.computeRoute(
        addresses,
        origin: const GeoPointModel(latitude: -23.5505, longitude: -46.6333),
      );

      // Origem = localização do usuário (latLng), não mais um endereço.
      expect(capturedBody!['origin'], {
        'location': {
          'latLng': {'latitude': -23.5505, 'longitude': -46.6333},
        },
      });
      // Destino continua sendo o último endereço do formulário.
      expect(capturedBody!['destination'], {'address': 'Av. D'});
      // Todos os endereços viram paradas: A, B e C como intermediários.
      expect(capturedBody!['intermediates'], [
        {'address': 'Av. A'},
        {'address': 'Rua B'},
        {'address': 'Rua C'},
      ]);
      expect(capturedBody!['travelMode'], 'DRIVE');
      expect(capturedBody!['optimizeWaypointOrder'], isTrue);
    });

    test('parseia a resposta com waypoints na ordem otimizada', () async {
      final service = _serviceReturning(_sampleRoutesPayload());

      final result = await service.computeRoute(addresses);

      switch (result) {
        case Ok<RouteModel>():
          final route = result.value;
          // Waypoints na ordem da rota: origem → otimizado (C,B) → destino.
          expect(
            route.waypoints.map((w) => w.address),
            orderedEquals(['Av. A', 'Rua C', 'Rua B', 'Av. D']),
          );
          expect(route.waypoints.first.location.latitude, -23.1);
          expect(route.waypoints.last.location.latitude, -23.4);
          expect(
            route.optimizedIntermediateWaypointIndex,
            orderedEquals([1, 0]),
          );
          expect(route.distanceMeters, 12500);
          expect(route.durationSeconds, 1628);
          expect(route.polylinePoints, isNotEmpty);
          // Getter de origem/destino derivado dos waypoints (SSOT).
          expect(route.origin.latitude, -23.1);
          expect(route.destination.latitude, -23.4);
        case Error<RouteModel>():
          fail('esperava Ok, recebi erro: ${result.error}');
      }
    });

    test('duração ISO-8601 é convertida para segundos', () async {
      final service =
          _serviceReturning(_sampleRoutesPayload(duration: 'PT27M8S'));

      final result = await service.computeRoute(addresses);

      switch (result) {
        case Ok<RouteModel>():
          expect(result.value.durationSeconds, 1628);
        case Error<RouteModel>():
          fail('esperava Ok, recebi erro: ${result.error}');
      }
    });

    test('com origem do usuário, waypoints incluem a localização e userOrigin é marcada',
        () async {
      final service = _serviceReturning(_userOriginRoutesPayload());

      final result = await service.computeRoute(
        addresses,
        origin: const GeoPointModel(latitude: -23.5505, longitude: -46.6333),
      );

      switch (result) {
        case Ok<RouteModel>():
          final route = result.value;
          // 5 waypoints: origem do usuário + os 4 endereços como paradas.
          expect(
            route.waypoints.map((w) => w.address),
            orderedEquals(
              ['Sua localização', 'Av. A', 'Rua B', 'Rua C', 'Av. D'],
            ),
          );
          expect(route.waypoints.first.location.latitude, -23.5505);
          expect(route.waypoints.first.location.longitude, -46.6333);
          // userOrigin marca a origem para a tela não numerar o usuário.
          expect(route.userOrigin, isNotNull);
          expect(route.userOrigin!.latitude, -23.5505);
          expect(route.userOrigin!.longitude, -46.6333);
          expect(route.destination.latitude, -23.4);
        case Error<RouteModel>():
          fail('esperava Ok, recebi erro: ${result.error}');
      }
    });

    test('origem do usuário sem endereços vira Result.error (sem rede)',
        () async {
      final adapter = _FakeHttpClientAdapter((options, stream) async {
        fail('nenhuma requisição deve ser feita sem endereço de destino');
      });
      final service = MapService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: 'test-key',
      );

      final result = await service.computeRoute(
        const [],
        origin: const GeoPointModel(latitude: -23.5505, longitude: -46.6333),
      );

      expect(result, isA<Error<RouteModel>>());
    });

    test('sem legs usa os endereços solicitados como fallback', () async {
      final service = _serviceReturning({
        'routes': [
          {
            'distanceMeters': 100,
            'duration': '10s',
            'polyline': {'encodedPolyline': ''},
            'legs': [],
          },
        ],
      });

      final result = await service.computeRoute(['Av. A', 'Av. D']);

      switch (result) {
        case Ok<RouteModel>():
          expect(
            result.value.waypoints.map((w) => w.address),
            orderedEquals(['Av. A', 'Av. D']),
          );
        case Error<RouteModel>():
          fail('esperava Ok, recebi erro: ${result.error}');
      }
    });

    test('sem rotas retornadas vira Result.error', () async {
      final service = _serviceReturning({'routes': []});

      final result = await service.computeRoute(addresses);

      expect(result, isA<Error<RouteModel>>());
    });

    test('resposta vazia vira Result.error', () async {
      final adapter = _FakeHttpClientAdapter((options, stream) async {
        return ResponseBody.fromString(
          '',
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });
      final service = MapService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: 'test-key',
      );

      final result = await service.computeRoute(addresses);

      expect(result, isA<Error<RouteModel>>());
    });

    test('DioException vira Result.error com a mensagem da exceção', () async {
      final adapter = _FakeHttpClientAdapter((options, stream) async {
        throw DioException(requestOptions: options, message: 'no internet');
      });
      final service = MapService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: 'test-key',
      );

      final result = await service.computeRoute(addresses);

      expect(result, isA<Error<RouteModel>>());
      expect(
        (result as Error<RouteModel>).error.toString(),
        contains('no internet'),
      );
    });

    test('chave vazia falha rápido com erro acionável (sem rede)', () async {
      final adapter = _FakeHttpClientAdapter((options, stream) async {
        fail('nenhuma requisição deve ser feita com chave ausente');
      });
      final service = MapService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: '',
      );

      final result = await service.computeRoute(addresses);

      expect(result, isA<Error<RouteModel>>());
      expect(
        (result as Error<RouteModel>).error.toString(),
        contains('GOOGLE_MAPS_API_KEY'),
      );
    });

    test('menos de 2 endereços vira Result.error', () async {
      final adapter = _FakeHttpClientAdapter((options, stream) async {
        fail('nenhuma requisição deve ser feita com waypoints insuficientes');
      });
      final service = MapService(
        dio: Dio()..httpClientAdapter = adapter,
        apiKey: 'test-key',
      );

      final result = await service.computeRoute(['Av. A']);

      expect(result, isA<Error<RouteModel>>());
    });
  });
}