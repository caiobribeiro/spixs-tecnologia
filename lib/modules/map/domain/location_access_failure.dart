sealed class LocationAccessFailure implements Exception {
  const LocationAccessFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class LocationPermissionDeniedFailure extends LocationAccessFailure {
  const LocationPermissionDeniedFailure()
    : super('Permissão de localização negada pelo usuário.');
}

final class LocationServiceDisabledFailure extends LocationAccessFailure {
  const LocationServiceDisabledFailure()
    : super('O GPS do dispositivo está desligado.');
}
