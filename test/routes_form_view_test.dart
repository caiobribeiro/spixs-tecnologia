// Testes de widget do formulário "Para onde vamos?".
//
// Foco: botão "Confirmar rota" só clicável quando TODOS os endereços estão
// preenchidos, e remoção de pontos adicionados (mantendo o mínimo A/B/C).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/app_dependency_injection.dart';
import 'package:spixs_tecnologia/modules/home/presenter/routes_form_view.dart';

void main() {
  setUpAll(setupDependencyInjection);

  /// Botão "Confirmar rota" exibido na tela.
  ElevatedButton confirmButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoutesFormView()));
    await tester.pump();
  }

  testWidgets('botão Confirmar rota só habilita com todos os endereços',
      (tester) async {
    await pumpForm(tester);
    expect(find.text('Para onde vamos?'), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNull);

    // Preenche A e B apenas: continua desabilitado e mostra a instrução.
    await tester.enterText(find.byType(TextFormField).at(0), 'Rua A');
    await tester.enterText(find.byType(TextFormField).at(1), 'Rua B');
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNull);
    expect(find.text('Preencha os 3 endereços para continuar'), findsOneWidget);

    // Preenche C: habilita e esconde a instrução.
    await tester.enterText(find.byType(TextFormField).at(2), 'Rua C');
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNotNull);
    expect(find.text('Preencha os 3 endereços para continuar'), findsNothing);
  });

  testWidgets('ponto adicionado vazio desabilita o botão até ser preenchido',
      (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Rua A');
    await tester.enterText(find.byType(TextFormField).at(1), 'Rua B');
    await tester.enterText(find.byType(TextFormField).at(2), 'Rua C');
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Adicionar ponto'));
    await tester.pump();
    expect(find.byType(TextFormField), findsNWidgets(4));
    // Novo ponto vazio → desabilita de novo, com instrução de "todos".
    expect(confirmButton(tester).onPressed, isNull);
    expect(find.text('Preencha todos os endereços para continuar'),
        findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(3), 'Rua D');
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets('remove um ponto adicionado e o botão reage', (tester) async {
    await pumpForm(tester);

    // Sem pontos adicionados não há como remover.
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.tap(find.text('Adicionar ponto'));
    await tester.pump();
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.byIcon(Icons.close), findsNWidgets(4));

    // Preenche os 4 pontos e remove o último.
    for (var i = 0; i < 4; i++) {
      await tester.enterText(find.byType(TextFormField).at(i), 'Rua ${i + 1}');
    }
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNotNull);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pump();

    // Volta ao mínimo A/B/C: removeu o ponto D e o campo está preenchido.
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byIcon(Icons.close), findsNothing);
    expect(confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets('validação mostra "Campo obrigatório" em campos vazios',
      (tester) async {
    await pumpForm(tester);

    // Todos os campos vazios com autovalidate: mensagens na tela.
    expect(find.text('Campo obrigatório'), findsNWidgets(3));

    await tester.enterText(find.byType(TextFormField).at(0), 'Rua A');
    await tester.pump();
    expect(find.text('Campo obrigatório'), findsNWidgets(2));
  });
}