import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../../../shared/patterns/result.dart';
import '../../data/services/connectivity_service.dart';
import 'connectivity_repository.dart';

/// Concrete [ConnectivityRepository].
///
/// Owns the SSOT ([isOnline]) and translates the raw `connectivity_plus`
/// results into a simple online/offline boolean: any result different from
/// `none` counts as online.
class ConnectivityRepositoryImpl implements ConnectivityRepository {
  ConnectivityRepositoryImpl(this._service);

  final ConnectivityService _service;

  /// SSOT da conectividade. Começa otimista (online) e é corrigido pela
  /// primeira checagem ([startMonitoring]) e pelas mudanças do stream.
  final ValueNotifier<bool> _isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  ValueListenable<bool> get isOnline => _isOnline;

  @override
  Future<void> startMonitoring() async {
    // Uma única assinatura por ciclo de vida do app; idempotente.
    _subscription ??= _service.onConnectivityChanged.listen(
      _apply,
      // Falha da plataforma (ex.: MissingPluginException em testes ou canal
      // indisponível): mantém o último estado conhecido, sem derrubar o app.
      onError: (_) {},
    );

    // Estado inicial explícito: nem sempre o stream emite logo após assinar.
    final result = await _service.checkConnectivity();
    switch (result) {
      case Ok<List<ConnectivityResult>>():
        _apply(result.value);
      case Error<List<ConnectivityResult>>():
        // Sem estado conhecido: mantém o último valor do SSOT.
        return;
    }
  }

  /// Atualiza o SSOT traduzindo os resultados do plugin para online/offline.
  void _apply(List<ConnectivityResult> results) {
    _isOnline.value = !results.contains(ConnectivityResult.none);
  }
}