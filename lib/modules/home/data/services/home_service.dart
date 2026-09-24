import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../shared/patterns/result.dart';
import '../models/home_summary_model.dart';

class HomeService {
  HomeService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<Result<HomeSummaryModel>> getSummary() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isConnected = !results.contains(ConnectivityResult.none);

      return Result.ok(
        HomeSummaryModel(
          isConnected: isConnected,
          connectionLabel: _describe(results),
          message: isConnected ? 'You are online' : 'You are offline',
        ),
      );
    } on Exception catch (error) {
      return Result.error(error);
    }
  }

  String _describe(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return 'Wi-Fi';
    if (results.contains(ConnectivityResult.mobile)) return 'Mobile data';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    if (results.contains(ConnectivityResult.bluetooth)) return 'Bluetooth';
    if (results.contains(ConnectivityResult.vpn)) return 'VPN';
    if (results.contains(ConnectivityResult.satellite)) return 'Satellite';
    if (results.contains(ConnectivityResult.other)) return 'Other network';
    return 'No connection';
  }
}
