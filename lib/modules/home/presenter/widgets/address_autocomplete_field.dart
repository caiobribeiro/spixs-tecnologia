import 'package:flutter/material.dart';

import '../../../core/theme/domain/tokens/app_colors.dart';
import '../../../core/theme/domain/tokens/app_radii.dart';
import '../../../core/theme/domain/tokens/app_spacing.dart';
import '../../../core/theme/domain/tokens/app_typography.dart';
import '../../domain/entity/place_suggestion_entity.dart';

/// Campo de endereço com autocomplete do Google Places (design system Rota).
///
/// Componente de apresentação puro: recebe o controller, o validador, as
/// sugestões e expõe as interações via callbacks. Não resolve `getIt` nem
/// toca em repositórios — a busca e o estado das sugestões vivem no
/// `RoutesFormViewmodel`.
class AddressAutocompleteField extends StatelessWidget {
  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.validator,
    required this.hintText,
    required this.suggestions,
    required this.onChanged,
    required this.onSelected,
    this.removable = false,
    this.onRemove,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final String hintText;
  final List<PlaceSuggestionEntity> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<PlaceSuggestionEntity> onSelected;
  final bool removable;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo base: surface-200 · border · radius-md (tema global).
        TextFormField(
          controller: controller,
          // Só valida depois da PRIMEIRA interação do usuário com o campo:
          // no carregamento da tela nenhum erro aparece, mesmo vazio.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            // "Ponto A", "Ponto B", "Ponto C"... (endereço não preenchido).
            hintText: hintText,
            // Remove pontos adicionados; o mínimo A/B/C é fixo.
            suffixIcon: removable
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Remover $hintText',
                    onPressed: onRemove,
                  )
                : null,
          ),
        ),
        // Sugestões do autocomplete: cards surface-200 · radius-md · border.
        ..._buildSuggestions(),
      ],
    );
  }

  List<Widget> _buildSuggestions() {
    if (suggestions.isEmpty) {
      return const [];
    }

    return <Widget>[
      const SizedBox(height: AppSpacing.space2),
      for (var i = 0; i < suggestions.length; i++) ...[
        Card(
          margin: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusMd)),
            side: BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
            // main-text em body-strong, secundário em caption (ink-muted).
            title: Text(
              suggestions[i].mainText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyStrong,
            ),
            subtitle: suggestions[i].secondaryText.isEmpty
                ? null
                : Text(
                    suggestions[i].secondaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
            onTap: () => onSelected(suggestions[i]),
          ),
        ),
        if (i < suggestions.length - 1) const SizedBox(height: AppSpacing.space1),
      ],
    ];
  }
}