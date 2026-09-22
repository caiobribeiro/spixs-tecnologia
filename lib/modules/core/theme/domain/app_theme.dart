import 'package:flutter/material.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_radii.dart';
import 'tokens/app_spacing.dart';
import 'tokens/app_typography.dart';

/// Builds a Flutter [ThemeData] **estritamente** a partir dos tokens do
/// design system Rota (`Rota_Design_System.pdf`).
///
/// # Mapeamento (painel → tela de exemplo do DS)
///
/// | Token do DS            | ThemeData                                                    |
/// |------------------------|--------------------------------------------------------------|
/// | `surface-100`          | `scaffoldBackgroundColor` / `colorScheme.surface`            |
/// | `surface-200`          | cards, campos (`fillColor`), bottom sheet, modais            |
/// | `brand` / branco       | `colorScheme.primary`, botão elevado (ativo)                 |
/// | `border` / `ink-muted` | botão desabilitado (fundo `border`, texto `ink-muted`)       |
/// | `danger`               | `colorScheme.error`, borda de erro + mensagem `caption`      |
/// | `ink`                  | `colorScheme.onSurface`, textos principais                   |
/// | `ink-muted`            | `colorScheme.onSurfaceVariant`, legendas, placeholders       |
/// | 6 estilos tipográficos | `display→displaySmall`, `title→headlineSmall`,               |
/// |                        | `heading→titleMedium`, `body-strong→titleSmall/labelLarge`,  |
/// |                        | `body→bodyLarge/Medium`, `caption→bodySmall`                 |
/// | `radius-md`            | campos, botões e cards                                       |
/// | `radius-lg`            | bottom sheet, modais e CTA em destaque ([primaryCtaButtonStyle]) |
/// | `radius-sm`            | chips/badges                                                 |
abstract final class AppTheme {
  /// Botão de ação primária em destaque (ex.: botão **Iniciar**).
  ///
  /// Difere do botão elevado padrão apenas no raio: `radius-lg` (24px),
  /// conforme *"Botão Iniciar em destaque"* no DS.
  static ButtonStyle primaryCtaButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.border,
      disabledForegroundColor: AppColors.inkMuted,
      elevation: 0,
      textStyle: AppTypography.bodyStrong.copyWith(color: Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusLg)),
      ),
    );
  }

  /// Constrói o [ThemeData] completo do app a partir dos tokens do DS.
  static ThemeData build() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.brand,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.surface100,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceContainerLowest: AppColors.surface200,
      surfaceContainerLow: AppColors.surface200,
      surfaceContainer: AppColors.surface200,
      surfaceContainerHigh: AppColors.surface200,
      surfaceContainerHighest: AppColors.surface200,
    );

    final textTheme = TextTheme(
      displaySmall: AppTypography.display,
      headlineSmall: AppTypography.title,
      titleMedium: AppTypography.heading,
      titleSmall: AppTypography.bodyStrong,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.caption,
      labelLarge: AppTypography.bodyStrong,
      labelMedium: AppTypography.caption,
    );

    final inputDecorationTheme = InputDecorationTheme(
      // Campos: surface-200 · border · radius-md · padding space-3
      filled: true,
      fillColor: AppColors.surface200,
      contentPadding: const EdgeInsets.all(AppSpacing.space3),
      hintStyle: AppTypography.caption,
      labelStyle: AppTypography.body,
      floatingLabelStyle: AppTypography.caption,
      // Mensagem de erro abaixo do campo: caption / danger
      errorStyle: AppTypography.caption.copyWith(color: AppColors.danger),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusMd)),
        borderSide: BorderSide(color: AppColors.border),
      ),
      // Foco: brand ("foco em campos")
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusMd)),
        borderSide: BorderSide(color: AppColors.brand),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusMd)),
        borderSide: BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusMd)),
        borderSide: BorderSide(color: AppColors.danger),
      ),
    );

    // Botões: campo · botão · card de endereço → radius-md
    final elevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        // Botão inativo: fundo border, texto ink-muted
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.inkMuted,
        elevation: 0,
        textStyle: AppTypography.bodyStrong.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusMd)),
        ),
      ),
    );

    // Link de texto (ex.: "Adicionar ponto"): brand · body-strong · sem ícone
    final textButtonTheme = TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        disabledForegroundColor: AppColors.inkMuted,
        textStyle: AppTypography.bodyStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusSm)),
        ),
      ),
    );

    // Chips e badges de status → radius-sm
    final chipTheme = ChipThemeData(
      backgroundColor: AppColors.surface200,
      side: const BorderSide(color: AppColors.border),
      labelStyle: AppTypography.bodyStrong,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusSm)),
      ),
    );

    // Cards → surface-200 · radius-md
    final cardTheme = CardThemeData(
      color: AppColors.surface200,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusMd)),
      ),
    );

    // Bottom sheet de rota / modais → surface-200 · radius-lg
    final bottomSheetTheme = BottomSheetThemeData(
      backgroundColor: AppColors.surface200,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.radiusLg),
        ),
      ),
    );

    final dialogTheme = DialogThemeData(
      backgroundColor: AppColors.surface200,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusLg)),
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      // Fundo da tela → surface-100
      scaffoldBackgroundColor: AppColors.surface100,
      textTheme: textTheme,
      inputDecorationTheme: inputDecorationTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      textButtonTheme: textButtonTheme,
      chipTheme: chipTheme,
      cardTheme: cardTheme,
      bottomSheetTheme: bottomSheetTheme,
      dialogTheme: dialogTheme,
      // Divisores → border
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface100,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.title.copyWith(color: AppColors.ink),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
      ),
    );
  }
}