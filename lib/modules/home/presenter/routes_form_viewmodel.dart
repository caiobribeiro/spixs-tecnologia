import 'package:flutter/widgets.dart';

import '../../../shared/mixins/validation_mixin.dart';

/// Manages the state of the address form screen (`RoutesFormView`).
///
/// Single source of truth do formulário: é o [RoutesFormViewmodel] que possui
/// os controllers de cada campo de endereço (A/B/C...) e deriva o estado do
/// botão "Confirmar rota" a partir deles, seguindo o design system Rota:
/// o botão só é habilitado depois que **todos** os endereços exibidos estão
/// preenchidos (mínimo de [minimumAddresses] campos).
class RoutesFormViewmodel extends ChangeNotifier with ValidationMixin {
  RoutesFormViewmodel() {
    for (final controller in _addressControllers) {
      controller.addListener(_onAddressChanged);
    }
  }

  /// Quantidade mínima de endereços para habilitar a confirmação da rota.
  static const int minimumAddresses = 3;

  /// Controllers dos campos de endereço (SSOT do formulário).
  ///
  /// Começa com os 3 pontos A/B/C fixos da tela; "Adicionar ponto" inclui
  /// campos idênticos, sem limite fixo de pontos.
  final List<TextEditingController> _addressControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  /// Controllers de cada campo de endereço, na ordem exibida na tela.
  List<TextEditingController> get addressControllers =>
      List.unmodifiable(_addressControllers);

  /// Whether **every** displayed address field is filled.
  ///
  /// O botão "Confirmar rota" só pode ser clicado quando não há nenhum campo
  /// vazio na tela — validação de todos os endereços antes de prosseguir,
  /// não apenas o mínimo de [minimumAddresses] pontos.
  bool get canConfirm =>
      _addressControllers.length >= minimumAddresses &&
      _filledAddresses == _addressControllers.length;

  /// Whether an address field can be removed from the screen.
  ///
  /// Os [minimumAddresses] pontos mínimos (A/B/C) são fixos: a remoção só
  /// fica disponível quando existem campos adicionados além do mínimo.
  bool get canRemoveAddressField =>
      _addressControllers.length > minimumAddresses;

  /// Quantidade de campos preenchidos (ignora espaços em branco).
  int get _filledAddresses => _addressControllers
      .where((controller) => controller.text.trim().isNotEmpty)
      .length;

  /// Validates a single address field (see [ValidationMixin.isNotEmpty]).
  ///
  /// Endereço vazio → "Campo obrigatório" (borda `danger` + mensagem em
  /// caption/danger, conforme o design system).
  String? validateAddress(String? value) => isNotEmpty(value);

  /// Validates **every** displayed address field, returning the first error.
  ///
  /// Usado como rede de segurança na confirmação: o botão já é desabilitado
  /// enquanto houver campo vazio, mas o [Form] ainda valida ao confirmar.
  String? validateAllAddresses() {
    return combine([
      for (final controller in _addressControllers)
        () => isNotEmpty(controller.text),
    ]);
  }

  /// Adds a new address field identical to A/B/C, without a fixed limit.
  void addAddressField() {
    final controller = TextEditingController();
    controller.addListener(_onAddressChanged);
    _addressControllers.add(controller);
    notifyListeners();
  }

  /// Removes the address field at [index], unless it would leave fewer than
  /// [minimumAddresses] points on screen.
  ///
  /// O controller removido deixa de ser observado e é descartado para evitar
  /// vazamento de memória.
  void removeAddressField(int index) {
    if (!canRemoveAddressField) {
      return;
    }
    if (index < 0 || index >= _addressControllers.length) {
      return;
    }
    final controller = _addressControllers.removeAt(index);
    controller.removeListener(_onAddressChanged);
    controller.dispose();
    notifyListeners();
  }

  /// Placeholder do botão "Confirmar rota".
  ///
  /// A ação real (cálculo/confirmação da rota) será conectada ao backend de
  /// rotas do app quando o fluxo do módulo `map` for integrado.
  void confirmRoute() {
    // TODO: conectar à confirmação de rota (módulo map) quando disponível.
  }

  /// Reavalia o estado do botão enquanto o usuário digita nos campos.
  void _onAddressChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _addressControllers) {
      controller.removeListener(_onAddressChanged);
      controller.dispose();
    }
    super.dispose();
  }
}