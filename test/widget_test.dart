// Basic smoke test: the app boots and renders the home module view.

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/app_dependency_injection.dart';
import 'package:spixs_tecnologia/spixs_tecnologia_app.dart';

void main() {
  testWidgets('App boots and renders the home view', (WidgetTester tester) async {
    setupDependencyInjection();

    await tester.pumpWidget(const SpixsTecnologiaApp());
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
  });
}