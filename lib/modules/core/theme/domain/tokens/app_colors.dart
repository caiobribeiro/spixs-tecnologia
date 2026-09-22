import 'package:flutter/material.dart';

/// Color tokens from the **Rota design system**.
///
/// Source: `Rota_Design_System.pdf` — seção *Cores*.
///
/// Os tokens devem ser usados sempre por meio desta classe (single source
/// of truth). Nenhum `Color(0xFF...)` solto no código da UI.
abstract final class AppColors {
  /// `#2A6DF4` — Ações primárias: botão Iniciar, marcador de rota ativa,
  /// foco em campos.
  static const Color brand = Color(0xFF2A6DF4);

  /// `#12B76A` — Rota confirmada, entrega concluída, autenticação bem-sucedida.
  static const Color success = Color(0xFF12B76A);

  /// `#F59E0B` — Aviso de recálculo de rota, desvio detectado (não bloqueante).
  static const Color warning = Color(0xFFF59E0B);

  /// `#E5484D` — Erros, falha de autenticação, permissão negada, sem internet.
  static const Color danger = Color(0xFFE5484D);

  /// `#F7F8FA` — Fundo de tela.
  static const Color surface100 = Color(0xFFF7F8FA);

  /// `#FFFFFF` — Cards, bottom sheet, campos de texto, tela de bloqueio.
  static const Color surface200 = Colors.white;

  /// `#12141A` — Texto principal sobre `surface-100` e `surface-200`.
  static const Color ink = Color(0xFF12141A);

  /// `#5B6472` — Texto secundário, legendas, placeholders, endereços não
  /// preenchidos.
  static const Color inkMuted = Color(0xFF5B6472);

  /// `#E2E5EA` — Divisores, bordas de campos e cards em repouso.
  static const Color border = Color(0xFFE2E5EA);
}