import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../../../shared/patterns/result.dart';
import '../../data/services/connectivity_service.dart';
import 'connectivity_repository.dart';

class ConnectivityRepositoryImpl implements ConnectivityRepository {
  ConnectivityRepositoryImpl(this._service);

  final ConnectivityService _service;

  final ValueNotifier<bool> _isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  ValueListenable<bool> get isOnline => _isOnline;

  @override
  Future<void> startMonitoring() async {
    _subscription ??= _service.onConnectivityChanged.listen(
      _apply,

      onError: (_) {},
    );

    final result = await _service.checkConnectivity();
    switch (result) {
      case Ok<List<ConnectivityResult>>():
        _apply(result.value);
      case Error<List<ConnectivityResult>>():
        return;
    }
  }

  void _apply(List<ConnectivityResult> results) {
    _isOnline.value = !results.contains(ConnectivityResult.none);
  }
}
