import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:spixs_tecnologia/app_dependency_injection.dart';

import '../../../../shared/mixins/validation_mixin.dart';
import '../../../../shared/patterns/result.dart';
import '../../domain/entity/place_suggestion_entity.dart';
import '../../domain/repository/places_repository.dart';

/// Manages the state of the address form screen (`RoutesFormView`).
///
/// Single source of truth do formulário: é o [RoutesFormViewmodel] que possui
/// os controllers de cada campo de endereço (A/B/C...) e deriva o estado do
/// botão "Confirmar rota" a partir deles, seguindo o design system Rota:
/// o botão só é habilitado depois que **todos** os endereços exibidos estão
/// preenchidos (mínimo de [minimumAddresses] campos).
///
/// Também coordena o **autocomplete do Google Places**: para cada campo, as
/// sugestões são buscadas em [searchDebounce] após a última tecla digitada
/// e ficam disponíveis via [suggestionsFor].
class RoutesFormViewmodel extends ChangeNotifier with ValidationMixin {
  RoutesFormViewmodel({
    this._placesRepository,
    this.searchDebounce = const Duration(milliseconds: 350),
  }) {
    for (final controller in _addressControllers) {
      controller.addListener(_onAddressChanged);
    }
  }

  /// Quantidade mínima de endereços para habilitar a confirmação da rota.
  static const int minimumAddresses = 3;

  /// Comprimento mínimo de texto para disparar a busca de sugestões.
  static const int minAutocompleteQueryLength = 3;

  /// Repositório de autocomplete; injetável nos testes.
  ///
  /// Resolvido via DI na primeira busca (padrão do time, ver implementer
  /// agent) para não criar dependência no construtor.
  PlacesRepository? _placesRepository;
  PlacesRepository get _autocompleteRepository =>
      _placesRepository ??= getIt<PlacesRepository>();

  /// Tempo de espera após a última tecla antes de consultar a API.
  final Duration searchDebounce;

  /// Timers de debounce por índice de campo.
  final Map<int, Timer> _debounceTimers = {};

  /// Sugestões de endereço por índice de campo (estado transitório de UI).
  final Map<int, List<PlaceSuggestionEntity>> _suggestions = {};

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
    // Os índices mudaram: descarta buscas e sugestões pendentes.
    _cancelPendingSearches();
    _suggestions.clear();
    notifyListeners();
  }

  /// Sugestões de autocomplete exibidas abaixo do campo [index].
  List<PlaceSuggestionEntity> suggestionsFor(int index) =>
      List.unmodifiable(_suggestions[index] ?? const []);

  /// Handle chamado pelo campo [index] a cada tecla digitada pelo usuário.
  ///
  /// Consultas curtas não disparam busca; as demais são debounced em
  /// [searchDebounce] — se o usuário continua digitando, o timer anterior
  /// é cancelado e a API só é consultada após a pausa.
  void onAddressChanged(int index, String value) {
    _debounceTimers[index]?.cancel();

    final query = value.trim();
    if (query.length < minAutocompleteQueryLength) {
      _suggestions.remove(index);
      return;
    }

    _debounceTimers[index] = Timer(searchDebounce, () {
      _loadSuggestions(index, query);
    });
  }

  /// Preenche o campo [index] com a sugestão escolhida e fecha a lista.
  void selectSuggestion(int index, PlaceSuggestionEntity suggestion) {
    _debounceTimers[index]?.cancel();
    _addressControllers[index].text = suggestion.description;
    _suggestions.remove(index);
    notifyListeners();
  }

  /// Consulta o repositório e armazena o resultado por campo.
  Future<void> _loadSuggestions(int index, String query) async {
    final result = await _autocompleteRepository.autocompleteAddress(query);

    // O usuário pode ter continuado digitando enquanto a API respondia:
    // só aplica se a consulta ainda for a atual do campo.
    if (_addressControllers[index].text.trim() != query) {
      return;
    }

    switch (result) {
      case Ok<List<PlaceSuggestionEntity>>():
        final suggestions = result.value;
        _suggestions[index] = suggestions;
      case Error<List<PlaceSuggestionEntity>>():
        _suggestions.remove(index);
    }
    notifyListeners();
  }

  /// Cancela todos os timers de debounce pendentes.
  void _cancelPendingSearches() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }

  /// Coleta os endereços preenchidos (SSOT dos inputs) para repassar à tela
  /// do mapa na navegação.
  ///
  /// A rota **não** é calculada aqui: ela é calculada na entrada do mapa,
  /// inserindo a localização do usuário como origem da requisição. A
  /// validação do [Form] garante ≥ [minimumAddresses] endereços preenchidos;
  /// este método apenas filtra espaços em branco e preserva a ordem A/B/C.
  List<String> collectAddresses() {
    return [
      for (final controller in _addressControllers)
        if (controller.text.trim().isNotEmpty) controller.text.trim(),
    ];
  }

  /// Reavalia o estado do botão enquanto o usuário digita nos campos.
  void _onAddressChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelPendingSearches();
    for (final controller in _addressControllers) {
      controller.removeListener(_onAddressChanged);
      controller.dispose();
    }
    super.dispose();
  }
}
