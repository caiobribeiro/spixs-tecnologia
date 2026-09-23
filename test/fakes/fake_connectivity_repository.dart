import 'package:flutter/foundation.dart';

import 'package:spixs_tecnologia/modules/core/connectivity/domain/repository/connectivity_repository.dart';

/// Deterministic [ConnectivityRepository] for tests: never touches the
/// `connectivity_plus` platform channel.
class FakeConnectivityRepository implements ConnectivityRepository {
  FakeConnectivityRepository({bool online = true})
      : _isOnline = ValueNotifier<bool>(online);

  final ValueNotifier<bool> _isOnline;

  /// Quantas vezes [startMonitoring] foi chamado.
  int startMonitoringCalls = 0;

  @override
  ValueListenable<bool> get isOnline => _isOnline;

  @override
  Future<void> startMonitoring() async {
    startMonitoringCalls++;
  }

  /// Simula um evento do stream de conectividade.
  void setOnline(bool value) => _isOnline.value = value;
}