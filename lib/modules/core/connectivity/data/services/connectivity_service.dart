import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../../shared/patterns/result.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<Result<List<ConnectivityResult>>> checkConnectivity() async {
    try {
      return Result.ok(await _connectivity.checkConnectivity());
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
