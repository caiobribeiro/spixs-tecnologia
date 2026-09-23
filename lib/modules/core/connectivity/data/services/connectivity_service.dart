import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../../shared/patterns/result.dart';

/// Core: connectivity data source.
///
/// Thin wrapper around the `connectivity_plus` plugin exposing the two
/// operations the connectivity listener needs: a one-shot
/// [checkConnectivity] (initial state) and the continuous
/// [onConnectivityChanged] stream. Results are encapsulated in [Result] so
/// platform failures are explicit at the call site.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Current network state (one-shot), used to seed the initial state.
  Future<Result<List<ConnectivityResult>>> checkConnectivity() async {
    try {
      return Result.ok(await _connectivity.checkConnectivity());
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  /// Stream of network state changes while the app is running.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}