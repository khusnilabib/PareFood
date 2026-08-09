/// Material 3 themes built exclusively from brand tokens (PF-DOC-16 §3.9).
///
/// Light is the default; dark follows system and can be overridden in app
/// settings. Every `Pf*` widget derives its colours from the scheme below —
/// never from hard-coded values (DS-R01/DS-R02).
library;

import 'package:flutter/material.dart';

import 'pf_colors.dart';

/// Builds light and dark [ThemeData] for every PareFood app.
abstract final class AppTheme {
  /// Light theme (default).
  static ThemeData light() => _build(
    brightness: Brightness.light,
    primary: PfColors.primaryLight,
    onPrimary: PfColors.onPrimaryLight,
    secondary: PfColors.secondaryLight,
    tertiary: PfColors.tertiaryLight,
    surface: PfColors.surfaceLight,
    surfaceContainer: PfColors.surfaceContainerLight,
    error: PfColors.errorLight,
    onSurface: PfColors.onSurfaceLight,
    onSurfaceVariant: PfColors.onSurfaceVariantLight,
    outline: PfColors.outlineLight,
  );

  /// Dark theme — automatic follow-system in apps.
  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    primary: PfColors.primaryDark,
    onPrimary: PfColors.onPrimaryDark,
    secondary: PfColors.secondaryDark,
    tertiary: PfColors.tertiaryDark,
    surface: PfColors.surfaceDark,
    surfaceContainer: PfColors.surfaceContainerDark,
    error: PfColors.errorDark,
    onSurface: PfColors.onSurfaceDark,
    onSurfaceVariant: PfColors.onSurfaceVariantDark,
    outline: PfColors.outlineDark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color onPrimary,
    required Color secondary,
    required Color tertiary,
    required Color surface,
    required Color surfaceContainer,
    required Color error,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primary.withValues(alpha: 0.12),
      onPrimaryContainer: primary,
      secondary: secondary,
      onSecondary: surface,
      secondaryContainer: secondary.withValues(alpha: 0.14),
      onSecondaryContainer: secondary,
      tertiary: tertiary,
      onTertiary: surface,
      tertiaryContainer: tertiary.withValues(alpha: 0.14),
      onTertiaryContainer: tertiary,
      error: error,
      onError: surface,
      errorContainer: error.withValues(alpha: 0.12),
      onErrorContainer: error,
      surface: surface,
      onSurface: onSurface,
      surfaceContainer: surfaceContainer,
      surfaceContainerHighest: surfaceContainer,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outline.withValues(alpha: 0.4),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: onSurface,
      onInverseSurface: surface,
      inversePrimary: primary,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
