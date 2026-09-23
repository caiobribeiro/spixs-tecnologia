import 'package:flutter/foundation.dart';

abstract class ConnectivityRepository {
  ValueListenable<bool> get isOnline;

  Future<void> startMonitoring();
}
