// Testes do GeocodingService (Google Geocoding API): parsing da resposta e
// propagação de erros, com um adapter HTTP simulado (mesma técnica do
// MapService).

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/map/data/models/geo_point_model.dart';
import 'package:spixs_tecnologia/modules/map/data/services/geocoding_service.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';

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

GeocodingService _serviceReturning(
  Map<String, dynamic> payload, {
  String apiKey = 'test-key',
  int statusCode = 200,
}) {
  final adapter = _FakeHttpClientAdapter((options, stream) async {
    return ResponseBody.fromString(jsonEncode(payload), statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
  });
  return GeocodingService(dio: Dio()..httpClientAdapter = adapter, apiKey: apiKey);
}

const _singleResult = <String, dynamic>{
  'results': [
    <String, dynamic>{
      'geometry': <String, dynamic>{
        'location': <String, dynamic>{'lat': -23.5505, 'lng': -46.6333},
      },
    },
  ],
  'status': 'OK',
};

void main() {
  group('GeocodingService.geocodeAddress', () {
    test('parseia as coordenadas do resultado principal', () async {
      final service = _serviceReturning(_singleResult);

      final result = await service.geocodeAddress('Av. Paulista, 1000');

      switch (result) {
        case Ok<GeoPointModel>():
          expect(result.value.latitude, -23.5505);
          expect(result.value.longitude, -46.6333);
        case Error<GeoPointModel>():
          fail('esperava Ok, recebi erro: ${result.error}');
      }
    });

    test('ZERO_RESULTS retorna erro', () async {
      final service = _serviceReturning(const <String, dynamic>{
        'results': <dynamic>[],
        'status': 'ZERO_RESULTS',
      });

      final result = await service.geocodeAddress('Endereço inexistente');

      expect(result, isA<Error<GeoPointModel>>());
    });

    test('resposta sem resultados retorna erro', () async {
      final service = _serviceReturning(const <String, dynamic>{
        'results': <dynamic>[],
        'status': 'OK',
      });

      final result = await service.geocodeAddress('Endereço vazio');

      expect(result, isA<Error<GeoPointModel>>());
    });

    test('chave ausente falha rápido sem chamar a API', () async {
      final service = GeocodingService(apiKey: '');

      final result = await service.geocodeAddress('Av. A');

      expect(result, isA<Error<GeoPointModel>>());
      expect(
        (result as Error<GeoPointModel>).error.toString(),
        contains('não configurada'),
      );
    });
  });
}