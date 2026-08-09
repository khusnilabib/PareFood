/// Layout, shape, motion and type tokens (PF-DOC-16 §3.4–§3.6).
library;

import 'package:flutter/material.dart';

/// Spacing scale (PF-DOC-16 §3.4).
abstract final class PfSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Shape scale (PF-DOC-16 §3.5).
abstract final class PfRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 28;
}

/// Motion durations and curves (PF-DOC-16 §3.6).
abstract final class PfMotion {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration complex = Duration(milliseconds: 350);

  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}

/// Typography tokens built on the Material 3 type scale with Plus Jakarta Sans
/// (PF-DOC-16 §3.3). Weights/curves follow the brand table.
abstract final class PfTypography {
  static const double display = 40;
  static const double headline = 28;
  static const double title = 20;
  static const double body = 15;
  static const double label = 13;
}
