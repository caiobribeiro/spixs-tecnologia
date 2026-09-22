/// Failure returned by the native authentication flow.
///
/// Carries a user-friendly [message] so the presentation layer can display
/// the reason without depending on plugin-specific exceptions.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  /// Human-readable failure reason (pt-BR).
  final String message;

  @override
  String toString() => message;
}