import 'package:flutter/material.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_radii.dart';
import 'tokens/app_spacing.dart';
import 'tokens/app_typography.dart';

abstract final class AppTheme {
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
      filled: true,
      fillColor: AppColors.surface200,
      contentPadding: const EdgeInsets.all(AppSpacing.space3),
      hintStyle: AppTypography.caption,
      labelStyle: AppTypography.body,
      floatingLabelStyle: AppTypography.caption,

      errorStyle: AppTypography.caption.copyWith(color: AppColors.danger),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusMd)),
        borderSide: BorderSide(color: AppColors.border),
      ),

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

    final elevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,

        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.inkMuted,
        elevation: 0,
        textStyle: AppTypography.bodyStrong.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusMd)),
        ),
      ),
    );

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

    final chipTheme = ChipThemeData(
      backgroundColor: AppColors.surface200,
      side: const BorderSide(color: AppColors.border),
      labelStyle: AppTypography.bodyStrong,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusSm)),
      ),
    );

    final cardTheme = CardThemeData(
      color: AppColors.surface200,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusMd)),
      ),
    );

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

      scaffoldBackgroundColor: AppColors.surface100,
      textTheme: textTheme,
      inputDecorationTheme: inputDecorationTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      textButtonTheme: textButtonTheme,
      chipTheme: chipTheme,
      cardTheme: cardTheme,
      bottomSheetTheme: bottomSheetTheme,
      dialogTheme: dialogTheme,

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
