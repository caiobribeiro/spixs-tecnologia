/// Failures of the location access flow.
///
/// Typed exceptions allow the presentation layer to switch on the exact
/// cause (permission denied vs GPS off vs generic failure) instead of
/// inspecting raw platform exceptions.
///
/// `dart:core` `Exception` is a factory-constructor interface, so it is
/// implemented rather than extended.
sealed class LocationAccessFailure implements Exception {
  const LocationAccessFailure(this.message);

  /// User-facing (pt-BR) description of the failure.
  final String message;

  @override
  String toString() => message;
}

/// The user denied the location permission (or selected "never ask again",
/// so the platform dialog can no longer be shown).
final class LocationPermissionDeniedFailure extends LocationAccessFailure {
  const LocationPermissionDeniedFailure()
      : super('Permissão de localização negada pelo usuário.');
}

/// The device GPS / location service is disabled.
final class LocationServiceDisabledFailure extends LocationAccessFailure {
  const LocationServiceDisabledFailure()
      : super('O GPS do dispositivo está desligado.');
}