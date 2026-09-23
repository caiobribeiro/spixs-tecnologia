import 'package:flutter/material.dart';

import 'app_dependency_injection.dart';
import 'spixs_tecnologia_app.dart';

void main() {
  setupDependencyInjection();
  runApp(const SpixsTecnologiaApp());
}
