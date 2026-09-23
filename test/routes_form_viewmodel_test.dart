// Testes do formulário de endereços: validação e gestão dos campos A/B/C.

import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/home/presenter/routes_form_viewmodel.dart';

void main() {
  group('RoutesFormViewmodel', () {
    test('começa com os 3 pontos A/B/C vazios e botão desabilitado', () {
      final viewmodel = RoutesFormViewmodel();

      expect(viewmodel.addressControllers, hasLength(3));
      expect(viewmodel.canConfirm, isFalse);
      expect(viewmodel.canRemoveAddressField, isFalse);
    });

    test('habilita confirmação somente quando TODOS os campos estão preenchidos',
        () {
      final viewmodel = RoutesFormViewmodel();

      // Preenche apenas 2 de 3: ainda desabilitado.
      viewmodel.addressControllers[0].text = 'Rua A';
      viewmodel.addressControllers[1].text = 'Rua B';
      expect(viewmodel.canConfirm, isFalse);

      // Preenche o terceiro: habilita.
      viewmodel.addressControllers[2].text = 'Rua C';
      expect(viewmodel.canConfirm, isTrue);
    });

    test('com ponto extra, exige que TODOS os campos estejam preenchidos', () {
      final viewmodel = RoutesFormViewmodel();
      viewmodel.addAddressField();
      expect(viewmodel.addressControllers, hasLength(4));

      // 3 preenchidos + 1 vazio → ainda desabilitado (validação de todos).
      viewmodel.addressControllers[0].text = 'Rua A';
      viewmodel.addressControllers[1].text = 'Rua B';
      viewmodel.addressControllers[2].text = 'Rua C';
      expect(viewmodel.canConfirm, isFalse);

      // Preenche o 4º → habilita.
      viewmodel.addressControllers[3].text = 'Rua D';
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

    test('validateAllAddresses retorna o primeiro erro encontrado', () {
      final viewmodel = RoutesFormViewmodel();
      viewmodel.addressControllers[0].text = 'Rua A';
      viewmodel.addressControllers[1].text = '   ';
      viewmodel.addressControllers[2].text = 'Rua C';

      expect(viewmodel.validateAllAddresses(), 'Campo obrigatório');
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
}