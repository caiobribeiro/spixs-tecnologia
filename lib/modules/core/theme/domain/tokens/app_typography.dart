import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography tokens from the **Rota design system**.
///
/// Source: `Rota_Design_System.pdf` — seção *Tipografia*.
///
/// Família única do DS:
/// `system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif`.
///
/// Flutter não suporta font-stacks; o [TextStyle.fontFamily] fica nulo
/// (padrão do SO) e o `fontFamilyFallback` reproduz a ordem da stack.
/// No Android rende Roboto; no iOS, SF Pro; no desktop, Segoe UI — exatamente
/// o comportamento previsto pelo design system.
///
/// Tamanhos e alturas de linha são exatos (altura = `lineHeight / fontSize`).
abstract final class AppTypography {
  /// `34px / 40px / 700` — Nome do app na tela de bloqueio.
  static TextStyle get display => const TextStyle(
        fontSize: 34,
        height: 40 / 34,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  /// `22px / 28px / 700` — Título de tela (ex.: "Para onde vamos?").
  static TextStyle get title => const TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  /// `17px / 24px / 600` — Cabeçalho de card ou seção (ex.: "Ordem otimizada").
  static TextStyle get heading => const TextStyle(
        fontSize: 17,
        height: 24 / 17,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  /// `15px / 22px / 600` — Texto de destaque em listas, labels de botão.
  static TextStyle get bodyStrong => const TextStyle(
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  /// `15px / 22px / 400` — Texto padrão: endereços, mensagens, conteúdo geral.
  static TextStyle get body => const TextStyle(
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
      );

  /// `13px / 18px / 400` — Legendas, distância/tempo estimado, texto auxiliar.
  ///
  /// Por padrão em `ink-muted` (legendas = texto secundário no DS).
  static TextStyle get caption => const TextStyle(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: AppColors.inkMuted,
      );
}