// Testes de widget do formulário "Para onde vamos?".
//
// Foco: botão "Confirmar rota" só clicável quando TODOS os endereços estão
// preenchidos, remoção de pontos adicionados (mantendo o mínimo A/B/C) e
// autocomplete com sugestões do Google Places (via repositório fake).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/app_dependency_injection.dart';
import 'package:spixs_tecnologia/app_routes.dart';
import 'package:spixs_tecnologia/modules/home/domain/entity/place_suggestion_entity.dart';
import 'package:spixs_tecnologia/modules/home/domain/repository/places_repository.dart';
import 'package:spixs_tecnologia/modules/home/presenter/routes_form_view/routes_form_view.dart';

import 'fakes/fake_places_repository.dart';

void main() {
  const suggestion = PlaceSuggestionEntity(
    placeId: 'ChIJ1',
    description: 'Av. Paulista, 1000 - Bela Vista, São Paulo - SP, Brasil',
    mainText: 'Av. Paulista, 1000',
    secondaryText: 'Bela Vista, São Paulo - SP, Brasil',
  );

  setUpAll(setupDependencyInjection);

  /// Sem rede nos testes: sobrescreve o repositório com um fake vazio.
  setUp(() {
    getIt.allowReassignment = true;
    getIt.registerSingleton<PlacesRepository>(FakePlacesRepository());
  });

  /// Botão "Confirmar rota" exibido na tela.
  ElevatedButton confirmButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoutesFormView()));
    await tester.pump();
  }

  /// Digita no campo [index] e avança o relógio para o debounce do
  /// autocomplete disparar e a resposta do fake ser aplicada.
  Future<void> typeAddress(WidgetTester tester, int index, String text) async {
    await tester.enterText(find.byType(TextFormField).at(index), text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  testWidgets('botão Confirmar rota só habilita com todos os endereços', (
    tester,
  ) async {
    await pumpForm(tester);
    expect(find.text('Para onde vamos?'), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNull);

    // Preenche A e B apenas: continua desabilitado e mostra a instrução.
    await typeAddress(tester, 0, 'Rua A');
    await typeAddress(tester, 1, 'Rua B');
    expect(confirmButton(tester).onPressed, isNull);
    expect(find.text('Preencha os 3 endereços para continuar'), findsOneWidget);

    // Preenche C: habilita e esconde a instrução.
    await typeAddress(tester, 2, 'Rua C');
    expect(confirmButton(tester).onPressed, isNotNull);
    expect(find.text('Preencha os 3 endereços para continuar'), findsNothing);
  });

  testWidgets('ponto adicionado vazio desabilita o botão até ser preenchido', (
    tester,
  ) async {
    await pumpForm(tester);

    await typeAddress(tester, 0, 'Rua A');
    await typeAddress(tester, 1, 'Rua B');
    await typeAddress(tester, 2, 'Rua C');
    expect(confirmButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Adicionar ponto'));
    await tester.pump();
    expect(find.byType(TextFormField), findsNWidgets(4));
    // Novo ponto vazio → desabilita de novo, com instrução de "todos".
    expect(confirmButton(tester).onPressed, isNull);
    expect(
      find.text('Preencha todos os endereços para continuar'),
      findsOneWidget,
    );

    await typeAddress(tester, 3, 'Rua D');
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
      await typeAddress(tester, i, 'Rua ${i + 1}');
    }
    expect(confirmButton(tester).onPressed, isNotNull);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pump();

    // Volta ao mínimo A/B/C: removeu o ponto D e o campo está preenchido.
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byIcon(Icons.close), findsNothing);
    expect(confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets('validação mostra "Campo obrigatório" em campos vazios', (
    tester,
  ) async {
    await pumpForm(tester);

    // Todos os campos vazios com autovalidate: mensagens na tela.
    expect(find.text('Campo obrigatório'), findsNWidgets(3));

    await typeAddress(tester, 0, 'Rua A');
    expect(find.text('Campo obrigatório'), findsNWidgets(2));
  });

  testWidgets('autocomplete exibe sugestões e a seleção preenche o campo', (
    tester,
  ) async {
    getIt.registerSingleton<PlacesRepository>(
      FakePlacesRepository(suggestions: const [suggestion]),
    );

    await pumpForm(tester);
    await typeAddress(tester, 0, 'Av Paulista');

    // Sugestão do Google Places renderizada como card abaixo do campo.
    expect(find.text('Av. Paulista, 1000'), findsOneWidget);
    expect(find.text('Bela Vista, São Paulo - SP, Brasil'), findsOneWidget);

    // Selecionar preenche o campo com a descrição completa e fecha a lista.
    await tester.tap(find.text('Av. Paulista, 1000'));
    await tester.pump();

    final field = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );
    expect(
      field.controller!.text,
      'Av. Paulista, 1000 - Bela Vista, São Paulo - SP, Brasil',
    );
    expect(find.text('Av. Paulista, 1000'), findsNothing);

    // Ponto A preenchido pelo autocomplete: ainda falta B e C.
    expect(confirmButton(tester).onPressed, isNull);
  });

  testWidgets('autocomplete não exibe sugestões para consulta curta', (
    tester,
  ) async {
    getIt.registerSingleton<PlacesRepository>(
      FakePlacesRepository(suggestions: const [suggestion]),
    );

    await pumpForm(tester);
    await typeAddress(tester, 0, 'Av');

    // Menos de 3 caracteres: nenhuma sugestão é buscada/exibida.
    expect(find.text('Av. Paulista, 1000'), findsNothing);
  });

  testWidgets('Confirmar rota navega para o mapa (/map) com os endereços', (
    tester,
  ) async {
    // Navigator que registra a rota empurrada sem construir o MapView
    // (o GoogleMap exige platform view, indisponível em widget tests). A
    // rota em si é calculada na entrada do mapa, não aqui no formulário.
    String? pushedRouteName;
    List<String>? pushedArguments;
    await tester.pumpWidget(
      MaterialApp(
        home: const RoutesFormView(),
        onGenerateRoute: (settings) {
          pushedRouteName = settings.name;
          pushedArguments = settings.arguments as List<String>?;
          return MaterialPageRoute<bool?>(
            settings: settings,
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
          );
        },
      ),
    );
    await tester.pump();

    // Preenche os 3 endereços para liberar o botão.
    await typeAddress(tester, 0, 'Rua A');
    await typeAddress(tester, 1, 'Rua B');
    await typeAddress(tester, 2, 'Rua C');
    expect(confirmButton(tester).onPressed, isNotNull);

    // Confirma: deve empurrar a rota /map repassando os endereços A/B/C.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(pushedRouteName, AppRoute.map.path);
    expect(pushedRouteName, '/map');
    expect(pushedArguments, orderedEquals(['Rua A', 'Rua B', 'Rua C']));
  });

  testWidgets('voltar do mapa com trajeto concluído limpa o formulário', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const RoutesFormView(),
        onGenerateRoute: (settings) => MaterialPageRoute<bool?>(
          settings: settings,
          builder: (_) => const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();

    // Preenche os 3 endereços e confirma (empurra o mapa dummy).
    await typeAddress(tester, 0, 'Rua A');
    await typeAddress(tester, 1, 'Rua B');
    await typeAddress(tester, 2, 'Rua C');
    expect(confirmButton(tester).onPressed, isNotNull);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    // Formulário já não está visível (mapa por cima).
    expect(find.text('Para onde vamos?'), findsNothing);

    // Usuário fez todo o trajeto: o mapa volta com `true` → form limpado.
    final mapContext = tester.element(find.byType(Scaffold).last);
    Navigator.of(mapContext).pop(true);
    await tester.pumpAndSettle();

    expect(find.text('Para onde vamos?'), findsOneWidget);
    // Campos de volta ao estado inicial: vazios e botão desabilitado.
    for (var i = 0; i < 3; i++) {
      final field = tester.widget<TextFormField>(
        find.byType(TextFormField).at(i),
      );
      expect(field.controller!.text, isEmpty);
    }
    expect(confirmButton(tester).onPressed, isNull);
  });
}
