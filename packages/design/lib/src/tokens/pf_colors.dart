/// Brand colour tokens (PF-DOC-16 §3.2).
///
/// Light and dark values are fixed — dynamic colour is off (PF-DOC-16 §3.1).
/// Semantic tokens are the single source of truth (DS-R02); widgets must never
/// hard-code colour values.
library;

import 'package:flutter/material.dart';

/// The ten PareFood brand tokens with their light/dark values.
class PfColors {
  const PfColors._();

  static const Color primaryLight = Color(0xFFE6382C); // PareRed
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color secondaryLight = Color(0xFFE8630C); // saffron
  static const Color tertiaryLight = Color(0xFF2E7D32); // leaf green
  static const Color surfaceLight = Color(0xFFF7F2EF);
  static const Color surfaceContainerLight = Color(0xFFF5EDEA);
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color onSurfaceLight = Color(0xFF221A19);
  static const Color onSurfaceVariantLight = Color(0xFF857370);
  static const Color outlineLight = Color(0xFF9A8682);

  static const Color primaryDark = Color(0xFFFFB4AB);
  static const Color onPrimaryDark = Color(0xFF690005);
  static const Color secondaryDark = Color(0xFFFFB77B);
  static const Color tertiaryDark = Color(0xFF81C784);
  static const Color surfaceDark = Color(0xFF201A19);
  static const Color surfaceContainerDark = Color(0xFF2B2321);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color onSurfaceDark = Color(0xFFF0DFDC);
  static const Color onSurfaceVariantDark = Color(0xFFD5C2BF);
  static const Color outlineDark = Color(0xFF9A8682);
}
