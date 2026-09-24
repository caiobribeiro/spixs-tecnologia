// Basic smoke test: the app boots and renders the home module gate
// (native authentication lock screen).

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/app_dependency_injection.dart';
import 'package:spixs_tecnologia/modules/core/auth/domain/auth_failure.dart';
import 'package:spixs_tecnologia/modules/core/auth/domain/repository/auth_repository.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';
import 'package:spixs_tecnologia/spixs_tecnologia_app.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  testWidgets('App boots and renders the home lock screen',
      (WidgetTester tester) async {
    setupDependencyInjection();

    // Autenticação nativa não roda em teste (sem plugin): usa um fake que
    // "falha" para manter o gate travado de forma determinística.
    getIt.allowReassignment = true;
    getIt.registerSingleton<AuthRepository>(
      FakeAuthRepository(Result.error(const AuthFailure('Tentativa falhou'))),
    );

    await tester.pumpWidget(const SpixsTecnologiaApp());
    await tester.pumpAndSettle();

    // O app inicia bloqueado: o conteúdo só é revelado após a autenticação.
    expect(find.text('Spixs Tecnologia'), findsOneWidget);
    expect(find.text('Desbloquear'), findsOneWidget);
    expect(find.text('Tentativa falhou'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}