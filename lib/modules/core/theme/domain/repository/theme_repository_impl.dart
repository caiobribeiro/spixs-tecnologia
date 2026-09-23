import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'theme_repository.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  ThemeRepositoryImpl([ThemeData? theme]) : _theme = theme ?? AppTheme.build();

  final ThemeData _theme;

  @override
  ThemeData get theme => _theme;
}
