import 'package:flutter/material.dart';

import '../../../app_dependency_injection.dart';
import '../../core/theme/domain/app_theme.dart';
import '../../core/theme/domain/tokens/app_spacing.dart';
import '../../core/theme/domain/tokens/app_typography.dart';
import 'routes_form_viewmodel.dart';

/// Form screen: "Para onde vamos?".
///
/// Autocomplete de endereços do design system Rota: começa com os 3 pontos
/// A/B/C ("Ponto A", "Ponto B", "Ponto C") e permite adicionar novos pontos
/// idênticos. O botão **Confirmar rota** (radius-lg) é habilitado somente
/// depois que os 3 endereços mínimos são preenchidos.
class RoutesFormView extends StatefulWidget {
  const RoutesFormView({super.key});

  @override
  State<RoutesFormView> createState() => _RoutesFormViewState();
}

class _RoutesFormViewState extends State<RoutesFormView> {
  final RoutesFormViewmodel _viewmodel = getIt<RoutesFormViewmodel>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewmodel,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                // Título da tela: estilo `title`, margem inferior `space-4`.
                Text(
                  'Para onde vamos?',
                  style: AppTypography.title,
                ),
                const SizedBox(height: AppSpacing.space4),
                ..._buildAddressFields(),
                const SizedBox(height: AppSpacing.space2),
                // Link "Adicionar ponto": brand · body-strong · sem ícone.
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _viewmodel.addAddressField,
                    child: const Text('Adicionar ponto'),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                ElevatedButton(
                  // CTA em destaque: radius-lg; inativo = fundo border +
                  // texto ink-muted, ativo = fundo brand + texto branco.
                  style: AppTheme.primaryCtaButtonStyle(),
                  onPressed:
                      _viewmodel.canConfirm ? _viewmodel.confirmRoute : null,
                  child: const Text('Confirmar rota'),
                ),
                if (!_viewmodel.canConfirm) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    'Preencha os 3 endereços para continuar',
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Campos de endereço A/B/C..., com `space-2` entre eles.
  List<Widget> _buildAddressFields() {
    final controllers = _viewmodel.addressControllers;
    return [
      for (var index = 0; index < controllers.length; index++) ...[
        if (index > 0) const SizedBox(height: AppSpacing.space2),
        TextFormField(
          controller: controllers[index],
          autovalidateMode: AutovalidateMode.always,
          validator: _viewmodel.validateAddress,
          decoration: InputDecoration(
            // "Ponto A", "Ponto B", "Ponto C"... (endereço não preenchido).
            hintText: 'Ponto ${_labelFor(index)}',
          ),
        ),
      ],
    ];
  }

  /// Rótulo do ponto: A, B, C... e números após Z.
  String _labelFor(int index) {
    if (index < 26) {
      return String.fromCharCode('A'.codeUnitAt(0) + index);
    }
    return '${index + 1}';
  }
}