// Testes de conformidade: os tokens e o ThemeData devem refletir
// exatamente os valores do Rota_Design_System.pdf.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spixs_tecnologia/modules/core/theme/domain/app_theme.dart';
import 'package:spixs_tecnologia/modules/core/theme/domain/tokens/app_colors.dart';
import 'package:spixs_tecnologia/modules/core/theme/domain/tokens/app_radii.dart';
import 'package:spixs_tecnologia/modules/core/theme/domain/tokens/app_spacing.dart';
import 'package:spixs_tecnologia/modules/core/theme/domain/tokens/app_typography.dart';

void main() {
  group('AppColors (seção Cores do DS)', () {
    test('cores correspondem aos hex do PDF', () {
      expect(AppColors.brand, const Color(0xFF2A6DF4));
      expect(AppColors.success, const Color(0xFF12B76A));
      expect(AppColors.warning, const Color(0xFFF59E0B));
      expect(AppColors.danger, const Color(0xFFE5484D));
      expect(AppColors.surface100, const Color(0xFFF7F8FA));
      expect(AppColors.surface200, Colors.white);
      expect(AppColors.ink, const Color(0xFF12141A));
      expect(AppColors.inkMuted, const Color(0xFF5B6472));
      expect(AppColors.border, const Color(0xFFE2E5EA));
    });
  });

  group('AppSpacing (seção Espaçamento do DS)', () {
    test('espaçamentos correspondem ao PDF', () {
      expect(AppSpacing.space1, 4);
      expect(AppSpacing.space2, 8);
      expect(AppSpacing.space3, 16);
      expect(AppSpacing.space4, 32);
    });
  });

  group('AppRadii (seção Raio do DS)', () {
    test('raios correspondem ao PDF', () {
      expect(AppRadii.radiusSm, 6);
      expect(AppRadii.radiusMd, 12);
      expect(AppRadii.radiusLg, 24);
    });
  });

  group('AppTypography (seção Tipografia do DS)', () {
    test('estilos correspondem a tamanho/altura/peso do PDF', () {
      expect(AppTypography.display.fontSize, 34);
      expect(AppTypography.display.height, 40 / 34);
      expect(AppTypography.display.fontWeight, FontWeight.w700);

      expect(AppTypography.title.fontSize, 22);
      expect(AppTypography.title.height, 28 / 22);
      expect(AppTypography.title.fontWeight, FontWeight.w700);

      expect(AppTypography.heading.fontSize, 17);
      expect(AppTypography.heading.height, 24 / 17);
      expect(AppTypography.heading.fontWeight, FontWeight.w600);

      expect(AppTypography.bodyStrong.fontSize, 15);
      expect(AppTypography.bodyStrong.height, 22 / 15);
      expect(AppTypography.bodyStrong.fontWeight, FontWeight.w600);

      expect(AppTypography.body.fontSize, 15);
      expect(AppTypography.body.height, 22 / 15);
      expect(AppTypography.body.fontWeight, FontWeight.w400);

      expect(AppTypography.caption.fontSize, 13);
      expect(AppTypography.caption.height, 18 / 13);
      expect(AppTypography.caption.fontWeight, FontWeight.w400);
    });

    test('cor de texto segue o DS (ink / legendas em ink-muted)', () {
      expect(AppTypography.display.color, AppColors.ink);
      expect(AppTypography.title.color, AppColors.ink);
      expect(AppTypography.heading.color, AppColors.ink);
      expect(AppTypography.bodyStrong.color, AppColors.ink);
      expect(AppTypography.body.color, AppColors.ink);
      expect(AppTypography.caption.color, AppColors.inkMuted);
    });
  });

  group('AppTheme (mapeamento de tokens → ThemeData)', () {
    final theme = AppTheme.build();

    test('fundo da tela = surface-100', () {
      expect(theme.scaffoldBackgroundColor, AppColors.surface100);
      expect(theme.colorScheme.surface, AppColors.surface100);
    });

    test('superfícies de cards/campos = surface-200', () {
      expect(theme.colorScheme.surfaceContainerLow, AppColors.surface200);
      expect(theme.cardTheme.color, AppColors.surface200);
      expect(theme.inputDecorationTheme.fillColor, AppColors.surface200);
    });

    test('cores semânticas = tokens do DS', () {
      expect(theme.colorScheme.primary, AppColors.brand);
      expect(theme.colorScheme.onPrimary, Colors.white);
      expect(theme.colorScheme.error, AppColors.danger);
      expect(theme.colorScheme.onSurface, AppColors.ink);
      expect(theme.colorScheme.onSurfaceVariant, AppColors.inkMuted);
      expect(theme.colorScheme.outline, AppColors.border);
    });

    test('campos: radius-md e bordas por estado', () {
      final enabled = theme.inputDecorationTheme.enabledBorder
          as OutlineInputBorder;
      final focused = theme.inputDecorationTheme.focusedBorder
          as OutlineInputBorder;
      final error = theme.inputDecorationTheme.errorBorder
          as OutlineInputBorder;

      expect(enabled.borderRadius, BorderRadius.circular(AppRadii.radiusMd));
      expect(enabled.borderSide.color, AppColors.border);
      expect(focused.borderSide.color, AppColors.brand);
      expect(error.borderSide.color, AppColors.danger);
      expect(
        theme.inputDecorationTheme.contentPadding,
        const EdgeInsets.all(AppSpacing.space3),
      );
      expect(theme.inputDecorationTheme.errorStyle?.color, AppColors.danger);
    });

    test('botão elevado: brand/branco ativo, border/ink-muted inativo', () {
      final style = theme.elevatedButtonTheme.style!;
      expect(
        style.backgroundColor?.resolve(const <WidgetState>{}),
        AppColors.brand,
      );
      expect(
        style.foregroundColor?.resolve(const <WidgetState>{}),
        Colors.white,
      );
      expect(
        style.backgroundColor
            ?.resolve(const <WidgetState>{WidgetState.disabled}),
        AppColors.border,
      );
      expect(
        style.foregroundColor
            ?.resolve(const <WidgetState>{WidgetState.disabled}),
        AppColors.inkMuted,
      );
    });

    test('CTA em destaque usa radius-lg', () {
      final shape =
          AppTheme.primaryCtaButtonStyle().shape?.resolve(const <WidgetState>{});
      final radius =
          ((shape as RoundedRectangleBorder).borderRadius as BorderRadius)
              .topLeft
              .x;
      expect(radius, AppRadii.radiusLg);
    });

    test('tipografia mapeada nas roles Material', () {
      expect(theme.textTheme.headlineSmall?.fontSize, AppTypography.title.fontSize);
      expect(theme.textTheme.bodyLarge?.fontSize, AppTypography.body.fontSize);
      expect(theme.textTheme.bodySmall?.fontSize, AppTypography.caption.fontSize);
      expect(theme.textTheme.labelLarge?.fontWeight, FontWeight.w600);
    });
  });
}