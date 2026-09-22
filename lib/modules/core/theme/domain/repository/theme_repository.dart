import 'package:flutter/material.dart';

/// Contract for accessing the app theme.
///
/// O [ThemeRepositoryImpl] é a single source of truth do tema aplicado
/// pelo app (arquitetura: `modules/core/theme/domain/repository`).
abstract interface class ThemeRepository {
  /// O [ThemeData] atual do app, construído a partir dos tokens do DS.
  ThemeData get theme;
}