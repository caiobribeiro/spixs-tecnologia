// Testes de widget do formulário "Para onde vamos?".
//
// Foco: botão "Confirmar rota" só clicável quando TODOS os endereços têm
// uma **sugestão selecionada** no autocomplete (texto digitado solto não
// basta), remoção de pontos adicionados (mantendo o mínimo A/B/C) e a
// validação visual que só aparece depois da primeira interação do usuário.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/app_dependency_injection.dart';
import 'package:spixs_tecnologia/app_routes.dart';
import 'package:spixs_tecnologia/modules/core/connectivity/domain/repository/connectivity_repository.dart';
import 'package:spixs_tecnologia/modules/home/domain/entity/place_suggestion_entity.dart';
import 'package:spixs_tecnologia/modules/home/domain/repository/places_repository.dart';
import 'package:spixs_tecnologia/modules/home/presenter/routes_form_view/routes_form_view.dart';

import 'fakes/fake_connectivity_repository.dart';
import 'fakes/fake_places_repository.dart';

void main() {
  const suggestionPaulista = PlaceSuggestionEntity(
    placeId: 'ChIJ-paulista',
    description: 'Av. Paulista, 1000 - Bela Vista, São Paulo - SP, Brasil',
    mainText: 'Av. Paulista, 1000',
    secondaryText: 'Bela Vista, São Paulo - SP, Brasil',
  );

  /// Sugestões distintas por campo (descrições únicas para asserções).
  const byInput = <String, List<PlaceSuggestionEntity>>{
    'Rua A': [
      PlaceSuggestionEntity(
        placeId: 'ChIJ-a',
        description: 'Rua A, 100 - Centro, São Paulo - SP, Brasil',
        mainText: 'Rua A, 100',
        secondaryText: 'Centro, São Paulo - SP, Brasil',
      ),
    ],
    'Rua B': [
      PlaceSuggestionEntity(
        placeId: 'ChIJ-b',
        description: 'Rua B, 200 - Bela Vista, São Paulo - SP, Brasil',
        mainText: 'Rua B, 200',
        secondaryText: 'Bela Vista, São Paulo - SP, Brasil',
      ),
    ],
    'Rua C': [
      PlaceSuggestionEntity(
        placeId: 'ChIJ-c',
        description: 'Rua C, 300 - Pinheiros, São Paulo - SP, Brasil',
        mainText: 'Rua C, 300',
        secondaryText: 'Pinheiros, São Paulo - SP, Brasil',
      ),
    ],
    'Rua D': [
      PlaceSuggestionEntity(
        placeId: 'ChIJ-d',
        description: 'Rua D, 400 - Lapa, São Paulo - SP, Brasil',
        mainText: 'Rua D, 400',
        secondaryText: 'Lapa, São Paulo - SP, Brasil',
      ),
    ],
  };

  setUpAll(setupDependencyInjection);

  /// Sem rede nos testes: sobrescreve os repositórios com fakes.
  setUp(() {
    getIt.allowReassignment = true;
    getIt.registerSingleton<PlacesRepository>(FakePlacesRepository());
    // Conectividade: fake online por padrão; testes offline trocam/ajustam.
    getIt.registerSingleton<ConnectivityRepository>(
      FakeConnectivityRepository(),
    );
  });

  /// Botão "Confirmar rota" exibido na tela.
  ElevatedButton confirmButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  /// Viewport alto: com 3+ campos e as sugestões do autocomplete abertas,
  /// o botão e a mensagem de orientação ficariam fora da área visível do
  /// ListView (lazy) no tamanho padrão 800×600.
  void setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpForm(WidgetTester tester) async {
    setTallViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: RoutesFormView()));
    await tester.pump();
  }

  /// Digita no campo [index] e avança o relógio para o debounce do
  /// autocomplete disparar e a resposta do fake ser aplicada.
  Future<void> typeQuery(WidgetTester tester, int index, String query) async {
    await tester.enterText(find.byType(TextFormField).at(index), query);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  /// Digita [query] no campo [index] e toca na sugestão [mainText] da lista.
  Future<void> fillWithSelection(
    WidgetTester tester,
    int index,
    String query,
    String mainText,
  ) async {
    await typeQuery(tester, index, query);
    await tester.tap(find.text(mainText));
    await tester.pump();
  }

  testWidgets(
    'botão Confirmar rota só habilita com todos os endereços selecionados '
    'na lista de sugestões',
    (tester) async {
      getIt.registerSingleton<PlacesRepository>(
        FakePlacesRepository(byInput: byInput),
      );
      await pumpForm(tester);
      expect(find.text('Para onde vamos?'), findsOneWidget);
      expect(confirmButton(tester).onPressed, isNull);
      expect(
        find.text('Preencha os 3 endereços para continuar'),
        findsOneWidget,
      );

      // Texto digitado sem selecionar: preenchido, mas ainda desabilitado
      // com a orientação de escolher uma sugestão.
      await typeQuery(tester, 0, 'Rua A');
      await typeQuery(tester, 1, 'Rua B');
      await typeQuery(tester, 2, 'Rua C');
      expect(confirmButton(tester).onPressed, isNull);
      expect(
        find.text('Selecione uma sugestão de endereço para cada campo'),
        findsOneWidget,
      );
      expect(
        find.text('Preencha os 3 endereços para continuar'),
        findsNothing,
      );

      // Seleciona apenas A: B e C seguem pendentes.
      await tester.tap(find.text('Rua A, 100'));
      await tester.pump();
      expect(confirmButton(tester).onPressed, isNull);

      // Seleciona B e C: habilita e esconde a orientação.
      await tester.tap(find.text('Rua B, 200'));
      await tester.pump();
      await tester.tap(find.text('Rua C, 300'));
      await tester.pump();
      expect(confirmButton(tester).onPressed, isNotNull);
      expect(
        find.text('Selecione uma sugestão de endereço para cada campo'),
        findsNothing,
      );
    },
  );

  testWidgets('ponto adicionado vazio desabilita o botão até ser selecionado', (
    tester,
  ) async {
    getIt.registerSingleton<PlacesRepository>(
      FakePlacesRepository(byInput: byInput),
    );
    await pumpForm(tester);

    await fillWithSelection(tester, 0, 'Rua A', 'Rua A, 100');
    await fillWithSelection(tester, 1, 'Rua B', 'Rua B, 200');
    await fillWithSelection(tester, 2, 'Rua C', 'Rua C, 300');
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

    await fillWithSelection(tester, 3, 'Rua D', 'Rua D, 400');
    expect(confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets('remove um ponto adicionado e o botão reage', (tester) async {
    getIt.registerSingleton<PlacesRepository>(
      FakePlacesRepository(byInput: byInput),
    );
    await pumpForm(tester);

    // Sem pontos adicionados não há como remover.
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.tap(find.text('Adicionar ponto'));
    await tester.pump();
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.byIcon(Icons.close), findsNWidgets(4));

    // Seleciona os 4 pontos e remove o último.
    await fillWithSelection(tester, 0, 'Rua A', 'Rua A, 100');
    await fillWithSelection(tester, 1, 'Rua B', 'Rua B, 200');
    await fillWithSelection(tester, 2, 'Rua C', 'Rua C, 300');
    await fillWithSelection(tester, 3, 'Rua D', 'Rua D, 400');
    expect(confirmButton(tester).onPressed, isNotNull);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pump();

    // Volta ao mínimo A/B/C: removeu o ponto D e os demais seguem
    // selecionados (seleções rebaseadas).
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byIcon(Icons.close), findsNothing);
    expect(confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets('sem validação no carregamento; vermelho só pós-interação', (
    tester,
  ) async {
    await pumpForm(tester);

    // Tela limpa: nenhum erro antes da primeira inserção.
    expect(find.text('Campo obrigatório'), findsNothing);

    // Digitar preenche (sem erro); limpar depois da interação → erro.
    await tester.enterText(find.byType(TextFormField).at(0), 'Rua A');
    await tester.pump();
    expect(find.text('Campo obrigatório'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.pump();
    expect(find.text('Campo obrigatório'), findsOneWidget);
  });

  testWidgets('autocomplete exibe sugestões e a seleção preenche o campo', (
    tester,
  ) async {
    getIt.registerSingleton<PlacesRepository>(
      FakePlacesRepository(suggestions: const [suggestionPaulista]),
    );

    await pumpForm(tester);
    await typeQuery(tester, 0, 'Av Paulista');

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

    // Ponto A selecionado pelo autocomplete: ainda faltam B e C.
    expect(confirmButton(tester).onPressed, isNull);
  });

  testWidgets('autocomplete não exibe sugestões para consulta curta', (
    tester,
  ) async {
    getIt.registerSingleton<PlacesRepository>(
      FakePlacesRepository(suggestions: const [suggestionPaulista]),
    );

    await pumpForm(tester);
    await typeQuery(tester, 0, 'Av');

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
    // Registra o fake de sugestões ANTES de montar o form: o viewmodel é
    // factory e resolve o repositório no momento em que a tela é criada.
    getIt.registerSingleton<PlacesRepository>(
      FakePlacesRepository(byInput: byInput),
    );
    setTallViewport(tester);
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

    // Seleciona os 3 endereços para liberar o botão.
    await fillWithSelection(tester, 0, 'Rua A', 'Rua A, 100');
    await fillWithSelection(tester, 1, 'Rua B', 'Rua B, 200');
    await fillWithSelection(tester, 2, 'Rua C', 'Rua C, 300');
    expect(confirmButton(tester).onPressed, isNotNull);

    // Confirma: deve empurrar a rota /map repassando as descrições das
    // sugestões selecionadas (A/B/C).
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(pushedRouteName, AppRoute.map.path);
    expect(pushedRouteName, '/map');
    expect(
      pushedArguments,
      orderedEquals([
        'Rua A, 100 - Centro, São Paulo - SP, Brasil',
        'Rua B, 200 - Bela Vista, São Paulo - SP, Brasil',
        'Rua C, 300 - Pinheiros, São Paulo - SP, Brasil',
      ]),
    );
  });

  testWidgets('offline: banner de aviso e Confirmar rota desabilitado', (
    tester,
  ) async {
    final connectivity = FakeConnectivityRepository(online: false);
    getIt.registerSingleton<ConnectivityRepository>(connectivity);
    getIt.registerSingleton<PlacesRepository>(
      FakePlacesRepository(byInput: byInput),
    );

    await pumpForm(tester);

    // Aviso no topo do formulário (design system) + mensagem sob o botão.
    expect(find.text('Sem conexão com a internet'), findsOneWidget);
    expect(
      find.text('Sem conexão com a internet — a rota não pode ser confirmada'),
      findsOneWidget,
    );

    // Mesmo com todos os endereços preenchidos e selecionados, o botão
    // continua desabilitado enquanto não houver internet.
    await fillWithSelection(tester, 0, 'Rua A', 'Rua A, 100');
    await fillWithSelection(tester, 1, 'Rua B', 'Rua B, 200');
    await fillWithSelection(tester, 2, 'Rua C', 'Rua C, 300');
    expect(confirmButton(tester).onPressed, isNull);
    expect(
      find.text('Sem conexão com a internet — a rota não pode ser confirmada'),
      findsOneWidget,
    );

    // Volta online: o aviso some e o botão habilita sem nova interação.
    connectivity.setOnline(true);
    await tester.pump();
    expect(find.text('Sem conexão com a internet'), findsNothing);
    expect(confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets('voltar do mapa com trajeto concluído limpa o formulário', (
    tester,
  ) async {
    getIt.registerSingleton<PlacesRepository>(
      FakePlacesRepository(byInput: byInput),
    );
    setTallViewport(tester);
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

    // Seleciona os 3 endereços e confirma (empurra o mapa dummy).
    await fillWithSelection(tester, 0, 'Rua A', 'Rua A, 100');
    await fillWithSelection(tester, 1, 'Rua B', 'Rua B, 200');
    await fillWithSelection(tester, 2, 'Rua C', 'Rua C, 300');
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
    // Campos de volta ao estado inicial: vazios, sem validação exibida
    // (remontados — nova geração do form) e botão desabilitado.
    for (var i = 0; i < 3; i++) {
      final field = tester.widget<TextFormField>(
        find.byType(TextFormField).at(i),
      );
      expect(field.controller!.text, isEmpty);
    }
    expect(find.text('Campo obrigatório'), findsNothing);
    expect(confirmButton(tester).onPressed, isNull);
  });
}