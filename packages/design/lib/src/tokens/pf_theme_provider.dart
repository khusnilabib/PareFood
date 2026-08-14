/// Theme providers with memoization to prevent unnecessary rebuilds.
/// Cached theme instances are reused across the app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pf_theme.dart';

/// Cached light theme provider. Rebuilds only when explicitly invalidated.
final lightThemeProvider = Provider<ThemeData>((ref) {
  return AppTheme.light();
});

/// Cached dark theme provider. Rebuilds only when explicitly invalidated.
final darkThemeProvider = Provider<ThemeData>((ref) {
  return AppTheme.dark();
});
