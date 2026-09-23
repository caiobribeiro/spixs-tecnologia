/// Reuses form validation logic across multiple widgets and viewmodels
/// without inheritance, keeping the code lean and decoupled.
mixin ValidationMixin {
  /// Validates that the field is not empty (ignores leading/trailing spaces).
  String? isNotEmpty(String? value, [String? message]) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Campo obrigatório';
    }
    return null;
  }

  /// Validates the minimum number of characters.
  String? hasFiveChars(String? value, [String? message]) {
    if (value != null && value.length < 5) {
      return message ?? 'Você deve informar pelo menos cinco caracteres';
    }
    return null;
  }

  /// Combines multiple validators, returning the first error found.
  String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final validation = validator();
      if (validation != null) {
        return validation;
      }
    }
    return null;
  }
}