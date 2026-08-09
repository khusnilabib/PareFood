/// pare_design — PareFood design system.
///
/// ## Responsibility (PF-DOC-10 §3.2 / PF-DOC-16)
/// Design tokens (colour, spacing, shape, motion, type), light/dark [AppTheme],
/// and the shared `Pf*` widget library consumed by all four apps.
///
/// ## Boundaries
/// - No business logic and no networking.
/// - Widgets use tokens / `ColorScheme` only — no hard-coded colours (DS-R01).
/// - User-facing strings are localised at call site via ARB (DS-R05); this
///   package never hard-codes UI text except neutral error fallbacks.
///
/// ## Consumers
/// Features and apps. Depends on `pare_core` (exceptions for error states) and
/// `pare_util`.
library;

export 'src/tokens/pf_colors.dart';
export 'src/tokens/pf_theme.dart';
export 'src/tokens/tokens.dart';
export 'src/widgets/pf_button.dart';
export 'src/widgets/pf_skeleton.dart';
export 'src/widgets/pf_state_views.dart';
export 'src/widgets/pf_status_badge.dart';
