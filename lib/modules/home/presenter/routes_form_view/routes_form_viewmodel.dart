import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:spixs_tecnologia/app_dependency_injection.dart';

import '../../../../modules/core/connectivity/domain/repository/connectivity_repository.dart';
import '../../../../shared/mixins/validation_mixin.dart';
import '../../../../shared/patterns/result.dart';
import '../../domain/entity/place_suggestion_entity.dart';
import '../../domain/repository/places_repository.dart';

class RoutesFormViewmodel extends ChangeNotifier with ValidationMixin {
  RoutesFormViewmodel({
    this._placesRepository,
    this._connectivityRepository,
    this.searchDebounce = const Duration(milliseconds: 350),
  }) {
    for (final controller in _addressControllers) {
      controller.addListener(_onAddressChanged);
    }
  }

  static const int minimumAddresses = 3;

  static const int minAutocompleteQueryLength = 3;

  PlacesRepository? _placesRepository;
  PlacesRepository get _autocompleteRepository =>
      _placesRepository ??= getIt<PlacesRepository>();

  ConnectivityRepository? _connectivityRepository;
  ConnectivityRepository get _connectivityRepo =>
      _connectivityRepository ??= getIt<ConnectivityRepository>();

  ValueListenable<bool> get isOnline => _connectivityRepo.isOnline;

  Future<void> startConnectivityMonitoring() =>
      _connectivityRepo.startMonitoring();

  final Duration searchDebounce;

  final Map<int, Timer> _debounceTimers = {};

  final Map<int, List<PlaceSuggestionEntity>> _suggestions = {};

  final Set<int> _selectedAddressIndexes = {};

  int _formEpoch = 0;
  int get formEpoch => _formEpoch;

  final List<TextEditingController> _addressControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  List<TextEditingController> get addressControllers =>
      List.unmodifiable(_addressControllers);

  bool get allAddressesFilled =>
      _addressControllers.length >= minimumAddresses &&
      _filledAddresses == _addressControllers.length;

  bool get allAddressesSelected =>
      _addressControllers.isNotEmpty &&
      _selectedAddressIndexes.length == _addressControllers.length;

  bool get canConfirm =>
      allAddressesFilled && allAddressesSelected && _canConfirmOnline;

  bool get _canConfirmOnline => _connectivityRepository?.isOnline.value ?? true;

  bool isAddressSelected(int index) => _selectedAddressIndexes.contains(index);

  bool get canRemoveAddressField =>
      _addressControllers.length > minimumAddresses;

  int get _filledAddresses => _addressControllers
      .where((controller) => controller.text.trim().isNotEmpty)
      .length;

  String? validateAddress(String? value) => isNotEmpty(value);

  String? validateAllAddresses() {
    return combine([
      for (final controller in _addressControllers)
        () => isNotEmpty(controller.text),
      for (var i = 0; i < _addressControllers.length; i++)
        () => isAddressSelected(i) ? null : 'Selecione um endereço sugerido',
    ]);
  }

  void addAddressField() {
    final controller = TextEditingController();
    controller.addListener(_onAddressChanged);
    _addressControllers.add(controller);
    notifyListeners();
  }

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

    _cancelPendingSearches();
    _suggestions.clear();

    _shiftSelectedIndexesAfterRemoval(index);
    notifyListeners();
  }

  void _shiftSelectedIndexesAfterRemoval(int removedIndex) {
    final shifted = <int>{};
    for (final index in _selectedAddressIndexes) {
      if (index == removedIndex) {
        continue;
      }
      shifted.add(index > removedIndex ? index - 1 : index);
    }
    _selectedAddressIndexes
      ..clear()
      ..addAll(shifted);
  }

  List<PlaceSuggestionEntity> suggestionsFor(int index) =>
      List.unmodifiable(_suggestions[index] ?? const []);

  void onAddressChanged(int index, String value) {
    _debounceTimers[index]?.cancel();
    _selectedAddressIndexes.remove(index);

    final query = value.trim();
    if (query.length < minAutocompleteQueryLength) {
      _suggestions.remove(index);
      return;
    }

    _debounceTimers[index] = Timer(searchDebounce, () {
      _loadSuggestions(index, query);
    });
  }

  void selectSuggestion(int index, PlaceSuggestionEntity suggestion) {
    _debounceTimers[index]?.cancel();
    _addressControllers[index].text = suggestion.description;
    _selectedAddressIndexes.add(index);
    _suggestions.remove(index);
    notifyListeners();
  }

  Future<void> _loadSuggestions(int index, String query) async {
    final result = await _autocompleteRepository.autocompleteAddress(query);

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

  void _cancelPendingSearches() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }

  List<String> collectAddresses() {
    return [
      for (final controller in _addressControllers)
        if (controller.text.trim().isNotEmpty) controller.text.trim(),
    ];
  }

  void resetForm() {
    _cancelPendingSearches();
    _suggestions.clear();
    _selectedAddressIndexes.clear();

    _formEpoch++;

    while (_addressControllers.length > minimumAddresses) {
      final controller = _addressControllers.removeLast();
      controller.removeListener(_onAddressChanged);
      controller.dispose();
    }
    for (final controller in _addressControllers) {
      controller.clear();
    }
    notifyListeners();
  }

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
