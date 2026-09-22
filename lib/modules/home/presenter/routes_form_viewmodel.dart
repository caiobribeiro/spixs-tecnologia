import 'package:flutter/widgets.dart';

/// Manages the state of the address form screen (`RoutesFormView`).
///
/// Single source of truth do formulário: é o [RoutesFormViewmodel] que possui
/// os controllers de cada campo de endereço (A/B/C...) e deriva o estado do
/// botão "Confirmar rota" a partir deles, seguindo o design system Rota:
/// o botão só é habilitado depois que os 3 endereços mínimos são preenchidos.
class RoutesFormViewmodel extends ChangeNotifier {
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

  /// Whether the minimum number of addresses is filled.
  bool get canConfirm => _filledAddresses >= minimumAddresses;

  /// Quantidade de campos preenchidos (ignora espaços em branco).
  int get _filledAddresses => _addressControllers
      .where((controller) => controller.text.trim().isNotEmpty)
      .length;

  /// Validates a single address field.
  ///
  /// Endereço vazio → "Campo obrigatório" (borda `danger` + mensagem em
  /// caption/danger, conforme o design system).
  String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  /// Adds a new address field identical to A/B/C, without a fixed limit.
  void addAddressField() {
    final controller = TextEditingController();
    controller.addListener(_onAddressChanged);
    _addressControllers.add(controller);
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