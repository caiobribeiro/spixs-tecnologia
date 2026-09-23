import 'package:flutter/material.dart';
import 'package:spixs_tecnologia/app_dependency_injection.dart';

import '../../../../app_routes.dart';
import '../../../../shared/widgets/connectivity_warning_banner.dart';
import '../../../core/theme/domain/app_theme.dart';
import '../../../core/theme/domain/tokens/app_spacing.dart';
import '../../../core/theme/domain/tokens/app_typography.dart';
import '../widgets/address_autocomplete_field.dart';
import 'routes_form_viewmodel.dart';

class RoutesFormView extends StatefulWidget {
  const RoutesFormView({super.key});

  @override
  State<RoutesFormView> createState() => _RoutesFormViewState();
}

class _RoutesFormViewState extends State<RoutesFormView> {
  final RoutesFormViewmodel _viewmodel = getIt<RoutesFormViewmodel>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _viewmodel.startConnectivityMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewmodel,
          builder: (context, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _viewmodel.isOnline,
              builder: (context, isOnline, _) {
                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    children: [
                      Text('Para onde vamos?', style: AppTypography.title),

                      if (!isOnline) ...[
                        const SizedBox(height: AppSpacing.space3),
                        const ConnectivityWarningBanner(),
                      ],
                      const SizedBox(height: AppSpacing.space4),
                      ..._buildAddressFields(),
                      const SizedBox(height: AppSpacing.space2),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _viewmodel.addAddressField,
                          child: const Text('Adicionar ponto'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      ElevatedButton(
                        style: AppTheme.primaryCtaButtonStyle(),
                        onPressed: _viewmodel.canConfirm ? _confirmRoute : null,
                        child: const Text('Confirmar rota'),
                      ),
                      if (!_viewmodel.canConfirm) ...[
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          !isOnline
                              ? 'Sem conexão com a internet — a rota não '
                                    'pode ser confirmada'
                              : _viewmodel.allAddressesFilled &&
                                    !_viewmodel.allAddressesSelected
                              ? 'Selecione uma sugestão de endereço para cada campo'
                              : _viewmodel.addressControllers.length >
                                    RoutesFormViewmodel.minimumAddresses
                              ? 'Preencha todos os endereços para continuar'
                              : 'Preencha os 3 endereços para continuar',
                          style: AppTypography.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildAddressFields() {
    final controllers = _viewmodel.addressControllers;
    return [
      for (var index = 0; index < controllers.length; index++) ...[
        if (index > 0) const SizedBox(height: AppSpacing.space2),
        AddressAutocompleteField(
          key: ValueKey('address_${_viewmodel.formEpoch}_$index'),
          controller: controllers[index],
          validator: _viewmodel.validateAddress,
          hintText: 'Ponto ${_labelFor(index)}',

          suggestions: _viewmodel.suggestionsFor(index),
          onChanged: (value) => _viewmodel.onAddressChanged(index, value),
          onSelected: (suggestion) {
            FocusScope.of(context).unfocus();
            _viewmodel.selectSuggestion(index, suggestion);
          },

          removable: _viewmodel.canRemoveAddressField,
          onRemove: () => _viewmodel.removeAddressField(index),
        ),
      ],
    ];
  }

  Future<void> _confirmRoute() async {
    if (_formKey.currentState?.validate() ?? false) {
      final addresses = _viewmodel.collectAddresses();

      final Object? routeFinished = await Navigator.of(context)
          .pushNamed(AppRoute.map.path, arguments: addresses);
      if (routeFinished == true) {
        _viewmodel.resetForm();
      }
    }
  }

  String _labelFor(int index) {
    if (index < 26) {
      return String.fromCharCode('A'.codeUnitAt(0) + index);
    }
    return '${index + 1}';
  }
}
