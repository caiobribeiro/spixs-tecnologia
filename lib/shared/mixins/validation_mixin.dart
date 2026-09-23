mixin ValidationMixin {
  String? isNotEmpty(String? value, [String? message]) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Campo obrigatório';
    }
    return null;
  }

  String? hasFiveChars(String? value, [String? message]) {
    if (value != null && value.length < 5) {
      return message ?? 'Você deve informar pelo menos cinco caracteres';
    }
    return null;
  }

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
