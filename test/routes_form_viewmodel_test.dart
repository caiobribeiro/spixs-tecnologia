// Testes do formulário de endereços: validação, gestão dos campos A/B/C e
// autocomplete do Google Places (com repositório fake).

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/home/domain/entity/place_suggestion_entity.dart';
import 'package:spixs_tecnologia/modules/home/presenter/routes_form_view/routes_form_viewmodel.dart';

import 'fakes/fake_connectivity_repository.dart';
import 'fakes/fake_places_repository.dart';

void main() {
  /// Constrói uma sugestão com [description] reutilizável nos testes.
  PlaceSuggestionEntity suggestion(String description) =>
      PlaceSuggestionEntity(
        placeId: 'ChIJ-$description',
        description: description,
        mainText: description,
        secondaryText: '',
      );

  group('RoutesFormViewmodel', () {
    test('começa com os 3 pontos A/B/C vazios e botão desabilitado', () {
      final viewmodel = RoutesFormViewmodel();

      expect(viewmodel.addressControllers, hasLength(3));
      expect(viewmodel.canConfirm, isFalse);
      expect(viewmodel.canRemoveAddressField, isFalse);
      expect(viewmodel.allAddressesSelected, isFalse);
    });

    test(
      'habilita confirmação somente quando TODOS os campos estão preenchidos '
      'E têm sugestão selecionada',
      () {
        final viewmodel = RoutesFormViewmodel();

        // Preenche apenas 2 de 3: ainda desabilitado.
        viewmodel.addressControllers[0].text = 'Rua A';
        viewmodel.addressControllers[1].text = 'Rua B';
        expect(viewmodel.canConfirm, isFalse);

        // Preenche o terceiro, ainda sem selecionar: texto solto não basta.
        viewmodel.addressControllers[2].text = 'Rua C';
        expect(viewmodel.allAddressesFilled, isTrue);
        expect(viewmodel.allAddressesSelected, isFalse);
        expect(viewmodel.canConfirm, isFalse);

        // Seleciona os três → habilita.
        viewmodel.selectSuggestion(0, suggestion('Rua A'));
        viewmodel.selectSuggestion(1, suggestion('Rua B'));
        expect(viewmodel.canConfirm, isFalse);
        viewmodel.selectSuggestion(2, suggestion('Rua C'));
        expect(viewmodel.canConfirm, isTrue);
      },
    );

    test('editar o texto depois de selecionar invalida a seleção', () async {
      final viewmodel = RoutesFormViewmodel(
        placesRepository: FakePlacesRepository(),
      );

      viewmodel.selectSuggestion(0, suggestion('Av. Paulista, 1000'));
      expect(viewmodel.isAddressSelected(0), isTrue);

      // O usuário segue digitando sobre o endereço escolhido: a seleção
      // deixa de valer até escolher uma nova sugestão.
      viewmodel.addressControllers[0].text = 'Av. Paulista, 1000 X';
      viewmodel.onAddressChanged(0, 'Av. Paulista, 1000 X');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(viewmodel.isAddressSelected(0), isFalse);
      expect(viewmodel.canConfirm, isFalse);
    });

    test('com ponto extra, exige que TODOS os campos estejam selecionados', () {
      final viewmodel = RoutesFormViewmodel();
      viewmodel.addAddressField();
      expect(viewmodel.addressControllers, hasLength(4));

      // 3 selecionados + 1 vazio → ainda desabilitado (validação de todos).
      for (var i = 0; i < 3; i++) {
        viewmodel.selectSuggestion(i, suggestion('Rua $i'));
      }
      expect(viewmodel.canConfirm, isFalse);

      // Seleciona o 4º → habilita.
      viewmodel.selectSuggestion(3, suggestion('Rua 3'));
      expect(viewmodel.canConfirm, isTrue);
    });

    test('ignora campos preenchidos apenas com espaços', () {
      final viewmodel = RoutesFormViewmodel();
      viewmodel.addressControllers[0].text = '   ';
      viewmodel.addressControllers[1].text = '\t';
      viewmodel.addressControllers[2].text = 'Rua C';

      expect(viewmodel.canConfirm, isFalse);
      expect(viewmodel.validateAddress('   '), 'Campo obrigatório');
    });

    test('validateAddress retorna erro para vazio e null para preenchido', () {
      final viewmodel = RoutesFormViewmodel();

      expect(viewmodel.validateAddress(null), 'Campo obrigatório');
      expect(viewmodel.validateAddress(''), 'Campo obrigatório');
      expect(viewmodel.validateAddress('Rua A'), isNull);
    });

    test('validateAllAddresses: vazio → obrigatório; preenchido sem seleção '
        '→ sugere escolher da lista', () {
      final viewmodel = RoutesFormViewmodel();
      viewmodel.addressControllers[0].text = 'Rua A';
      viewmodel.addressControllers[1].text = '   ';
      viewmodel.addressControllers[2].text = 'Rua C';

      // Campo vazio é o primeiro erro encontrado.
      expect(viewmodel.validateAllAddresses(), 'Campo obrigatório');

      // Tudo preenchido, mas sem seleção → rede de segurança da regra.
      viewmodel.addressControllers[1].text = 'Rua B';
      expect(viewmodel.validateAllAddresses(), 'Selecione um endereço sugerido');

      // Seleciona todos → passa.
      viewmodel.selectSuggestion(0, suggestion('Rua A'));
      viewmodel.selectSuggestion(1, suggestion('Rua B'));
      viewmodel.selectSuggestion(2, suggestion('Rua C'));
      expect(viewmodel.validateAllAddresses(), isNull);
    });

    test('addAddressField adiciona um campo idêntico e libera remoção', () {
      final viewmodel = RoutesFormViewmodel();

      viewmodel.addAddressField();
      expect(viewmodel.addressControllers, hasLength(4));
      expect(viewmodel.canRemoveAddressField, isTrue);
    });

    test('removeAddressField remove apenas o índice informado', () {
      final viewmodel = RoutesFormViewmodel();
      viewmodel.addAddressField();
      viewmodel.addressControllers[0].text = 'Rua A';
      viewmodel.addressControllers[3].text = 'Rua D';

      // Remove o índice 1 ('Ponto B', vazio): demais campos preservados.
      viewmodel.removeAddressField(1);

      expect(viewmodel.addressControllers, hasLength(3));
      expect(viewmodel.canRemoveAddressField, isFalse);
      expect(
        viewmodel.addressControllers.map((c) => c.text),
        orderedEquals(['Rua A', '', 'Rua D']),
      );
    });

    test('removeAddressField rebaseia as seleções dos campos restantes', () {
      final viewmodel = RoutesFormViewmodel();
      viewmodel.addAddressField(); // A, B, C, D
      for (var i = 0; i < 4; i++) {
        viewmodel.selectSuggestion(i, suggestion('Rua $i'));
      }
      expect(viewmodel.canConfirm, isTrue);

      // Remove o índice 1 ('Ponto B'): C desce para o índice 1, D para o 2
      // e as seleções acompanham — o form continua pronto para confirmar.
      viewmodel.removeAddressField(1);

      expect(viewmodel.addressControllers, hasLength(3));
      expect(viewmodel.isAddressSelected(0), isTrue);
      expect(viewmodel.isAddressSelected(1), isTrue);
      expect(viewmodel.isAddressSelected(2), isTrue);
      expect(viewmodel.canConfirm, isTrue);
    });

    test('removeAddressField respeita o mínimo de 3 pontos A/B/C', () {
      final viewmodel = RoutesFormViewmodel();

      // Com exatamente 3 campos, nenhuma remoção é permitida.
      viewmodel.removeAddressField(0);
      expect(viewmodel.addressControllers, hasLength(3));

      // Com 4 campos e um vazio, remover de volta aos 3 e tentar de novo.
      viewmodel.addAddressField();
      viewmodel.removeAddressField(3);
      expect(viewmodel.addressControllers, hasLength(3));

      viewmodel.removeAddressField(0);
      expect(viewmodel.addressControllers, hasLength(3));
    });

    test('removeAddressField ignora índices fora do intervalo', () {
      final viewmodel = RoutesFormViewmodel();
      viewmodel.addAddressField();

      viewmodel.removeAddressField(-1);
      viewmodel.removeAddressField(99);

      expect(viewmodel.addressControllers, hasLength(4));
    });
  });

  group('RoutesFormViewmodel — conectividade', () {
    test('sem conexão (repositório injetado) bloqueia a confirmação', () {
      final connectivity = FakeConnectivityRepository(online: false);
      final viewmodel = RoutesFormViewmodel(connectivityRepository: connectivity);

      // Todos preenchidos e selecionados, mas offline → desabilitado.
      for (var i = 0; i < 3; i++) {
        viewmodel.selectSuggestion(i, suggestion('Rua $i'));
      }
      expect(viewmodel.allAddressesFilled, isTrue);
      expect(viewmodel.allAddressesSelected, isTrue);
      expect(viewmodel.canConfirm, isFalse);

      // Volta online → habilita sem nova interação do usuário.
      connectivity.setOnline(true);
      expect(viewmodel.canConfirm, isTrue);
    });

    test('startConnectivityMonitoring delega ao repositório', () async {
      final connectivity = FakeConnectivityRepository();
      final viewmodel = RoutesFormViewmodel(connectivityRepository: connectivity);

      await viewmodel.startConnectivityMonitoring();
      await viewmodel.startConnectivityMonitoring();

      // Cada chamada re-checa o estado (subscription idempotente no repo).
      expect(connectivity.startMonitoringCalls, 2);
    });
  });

  group('RoutesFormViewmodel — autocomplete', () {
    const suggestion = PlaceSuggestionEntity(
      placeId: 'ChIJ1',
      description: 'Av. Paulista, 1000 - Bela Vista, São Paulo - SP, Brasil',
      mainText: 'Av. Paulista, 1000',
      secondaryText: 'Bela Vista, São Paulo - SP, Brasil',
    );

    test('consulta curta não dispara busca de sugestões', () async {
      final repository = FakePlacesRepository();
      final viewmodel = RoutesFormViewmodel(placesRepository: repository);

      viewmodel.addressControllers[0].text = 'Av';
      viewmodel.onAddressChanged(0, 'Av');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.calls, 0);
      expect(viewmodel.suggestionsFor(0), isEmpty);
    });

    test('busca sugestões após o debounce e as expõe por campo', () async {
      final repository = FakePlacesRepository(suggestions: const [suggestion]);
      final viewmodel = RoutesFormViewmodel(placesRepository: repository);

      viewmodel.addressControllers[1].text = 'Av Paulista';
      viewmodel.onAddressChanged(1, 'Av Paulista');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(repository.calls, 1);
      expect(repository.lastInput, 'Av Paulista');
      expect(viewmodel.suggestionsFor(1), hasLength(1));
      expect(viewmodel.suggestionsFor(0), isEmpty);
    });

    test('digitação contínua cancela a busca anterior (debounce)', () async {
      final repository = FakePlacesRepository(suggestions: const [suggestion]);
      final viewmodel = RoutesFormViewmodel(placesRepository: repository);

      viewmodel.addressControllers[0].text = 'Av';
      viewmodel.onAddressChanged(0, 'Av');
      viewmodel.addressControllers[0].text = 'Av P';
      viewmodel.onAddressChanged(0, 'Av P');
      viewmodel.addressControllers[0].text = 'Av Paulista';
      viewmodel.onAddressChanged(0, 'Av Paulista');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(repository.calls, 1);
      expect(repository.lastInput, 'Av Paulista');
      expect(viewmodel.suggestionsFor(0), hasLength(1));
    });

    test('selectSuggestion preenche o campo e limpa a lista', () async {
      final repository = FakePlacesRepository(suggestions: const [suggestion]);
      final viewmodel = RoutesFormViewmodel(placesRepository: repository);

      viewmodel.addressControllers[0].text = 'Av Paulista';
      viewmodel.onAddressChanged(0, 'Av Paulista');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(viewmodel.suggestionsFor(0), hasLength(1));

      viewmodel.selectSuggestion(0, suggestion);

      expect(
        viewmodel.addressControllers[0].text,
        'Av. Paulista, 1000 - Bela Vista, São Paulo - SP, Brasil',
      );
      expect(viewmodel.suggestionsFor(0), isEmpty);
      // A seleção marca o campo como escolhido da lista (regra do form).
      expect(viewmodel.isAddressSelected(0), isTrue);
    });

    test('falha da API limpa sugestões sem lançar exceção', () async {
      final repository = FakePlacesRepository(
        error: Exception('Places API error: REQUEST_DENIED'),
      );
      final viewmodel = RoutesFormViewmodel(placesRepository: repository);

      viewmodel.addressControllers[0].text = 'Av Paulista';
      viewmodel.onAddressChanged(0, 'Av Paulista');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(repository.calls, 1);
      expect(viewmodel.suggestionsFor(0), isEmpty);
    });
  });

  group('RoutesFormViewmodel — endereços para o mapa', () {
    test(
      'collectAddresses coleta os endereços preenchidos na ordem do form',
      () {
        final viewmodel = RoutesFormViewmodel();
        viewmodel.addressControllers[0].text = 'Av. Paulista, 1000';
        viewmodel.addressControllers[1].text = 'Rua B';
        viewmodel.addressControllers[2].text = 'Rua C';

        expect(
          viewmodel.collectAddresses(),
          orderedEquals(['Av. Paulista, 1000', 'Rua B', 'Rua C']),
        );
      },
    );

    test('pontos adicionados entram na coleta na ordem do form', () {
      final viewmodel = RoutesFormViewmodel();
      viewmodel.addAddressField();
      for (var i = 0; i < 4; i++) {
        viewmodel.addressControllers[i].text = 'Endereço ${i + 1}';
      }

      expect(
        viewmodel.collectAddresses(),
        orderedEquals(['Endereço 1', 'Endereço 2', 'Endereço 3', 'Endereço 4']),
      );
    });

    test('ignora campos vazios (ou só com espaços) ao coletar', () {
      final viewmodel = RoutesFormViewmodel();
      viewmodel.addressControllers[0].text = 'Av. Paulista, 1000';
      viewmodel.addressControllers[1].text = '   ';
      viewmodel.addressControllers[2].text = 'Rua C';
      viewmodel.addAddressField(); // 4º campo vazio

      expect(
        viewmodel.collectAddresses(),
        orderedEquals(['Av. Paulista, 1000', 'Rua C']),
      );
    });
  });

  group('RoutesFormViewmodel.resetForm', () {
    test('limpa textos, sugestões e campos adicionados (volta ao estado '
        'inicial A/B/C vazios)', () {
      final viewmodel = RoutesFormViewmodel();
      viewmodel.addressControllers[0].text = 'Av. Paulista, 1000';
      viewmodel.addressControllers[1].text = 'Rua B';
      viewmodel.addressControllers[2].text = 'Rua C';
      viewmodel.addAddressField();
      for (var i = 0; i < 4; i++) {
        viewmodel.selectSuggestion(i, suggestion('Rua $i'));
      }
      expect(viewmodel.addressControllers, hasLength(4));
      expect(viewmodel.canConfirm, isTrue);

      viewmodel.resetForm();

      expect(viewmodel.addressControllers, hasLength(3));
      expect(viewmodel.canConfirm, isFalse);
      expect(viewmodel.canRemoveAddressField, isFalse);
      // Seleções descartadas junto com os textos.
      expect(viewmodel.allAddressesSelected, isFalse);
      expect(viewmodel.formEpoch, 1);
      for (final controller in viewmodel.addressControllers) {
        expect(controller.text, isEmpty);
      }
    });

    test('descarta sugestões exibidas e cancela buscas pendentes', () async {
      const suggestion = PlaceSuggestionEntity(
        placeId: 'ChIJ1',
        description: 'Av. Paulista, 1000 - Bela Vista, São Paulo - SP, Brasil',
        mainText: 'Av. Paulista, 1000',
        secondaryText: 'Bela Vista, São Paulo - SP, Brasil',
      );
      final repository = FakePlacesRepository(suggestions: const [suggestion]);
      final viewmodel = RoutesFormViewmodel(placesRepository: repository);

      // Sugestões carregadas após o debounce → expostas no campo 0.
      viewmodel.addressControllers[0].text = 'Av Paulista';
      viewmodel.onAddressChanged(0, 'Av Paulista');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(viewmodel.suggestionsFor(0), hasLength(1));
      expect(repository.calls, 1);

      // Busca pendente (debounce agendado) antes do reset.
      viewmodel.onAddressChanged(0, 'av paulista');

      viewmodel.resetForm();

      expect(viewmodel.suggestionsFor(0), isEmpty);
      // O timer pendente foi cancelado: após o debounce não há nova busca
      // nem sugestões voltam a aparecer.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(repository.calls, 1);
      expect(viewmodel.suggestionsFor(0), isEmpty);
    });
  });
}
