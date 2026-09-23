import 'package:flutter/foundation.dart';

/// Core: internet connectivity contract.
///
/// Exposes the app-wide connectivity state as the **single source of truth**
/// ([isOnline]) and the [startMonitoring] entry point that wires the
/// `connectivity_plus` listener into that state. Screens observe [isOnline]
/// through their ViewModel; they never touch `connectivity_plus` directly.
abstract class ConnectivityRepository {
  /// Whether the device currently has internet access.
  ///
  /// Starts optimistic (online) and is corrected by the first check and by
  /// the platform stream once [startMonitoring] runs.
  ValueListenable<bool> get isOnline;

  /// Wires the connectivity listener and refreshes the initial state.
  ///
  /// Idempotent: subsequent calls reuse the existing subscription and only
  /// re-check the current state.
  Future<void> startMonitoring();
}
