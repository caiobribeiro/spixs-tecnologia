// Testes do gate de autenticação nativa da home: o restante do app só é
// exibido depois que a autenticação (biometria, senha ou PIN) é concluída.

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/app_dependency_injection.dart';
import 'package:spixs_tecnologia/modules/core/auth/domain/auth_failure.dart';
import 'package:spixs_tecnologia/modules/core/auth/domain/repository/auth_repository.dart';
import 'package:spixs_tecnologia/shared/patterns/result.dart';
import 'package:spixs_tecnologia/spixs_tecnologia_app.dart';

import 'fakes/fake_auth_repository.dart';

void _overrideAuthRepository(AuthRepository repository) {
  getIt.allowReassignment = true;
  getIt.registerSingleton<AuthRepository>(repository);
}

void main() {
  setUp(() {
    getIt.reset();
    setupDependencyInjection();
  });

  testWidgets('bloqueia o app enquanto a autenticação não é concluída',
      (WidgetTester tester) async {
    _overrideAuthRepository(
      FakeAuthRepository(Result.error(const AuthFailure('Tentativa falhou'))),
    );

    await tester.pumpWidget(const SpixsTecnologiaApp());
    await tester.pumpAndSettle();

    // Tela de bloqueio visível e conteúdo/home inacessível.
    expect(find.text('Desbloquear'), findsOneWidget);
    expect(find.text('Tentativa falhou'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('libera o conteudo do app depois da autenticação',
      (WidgetTester tester) async {
    _overrideAuthRepository(FakeAuthRepository(Result.ok(true)));

    await tester.pumpWidget(const SpixsTecnologiaApp());
    await tester.pumpAndSettle();

    // Gate liberado: após o login com `local_auth`, a navegação leva ao
    // formulário de endereços (tela com os 3 pontos A/B/C).
    expect(find.text('Para onde vamos?'), findsOneWidget);
    expect(find.text('Adicionar ponto'), findsOneWidget);
    expect(find.text('Confirmar rota'), findsOneWidget);
    expect(find.text('Desbloquear'), findsNothing);
  });
}