/// pare_util — pure helpers for PareFood.
///
/// ## Responsibility (PF-DOC-10 §3.2)
/// Formatters (IDR, date, ETA), input validators and string/number extensions.
///
/// ## Boundaries — must NOT
/// - Depend on `pare_core` (no domain knowledge)
/// - Import Flutter or perform any I/O
///
/// ## Consumers
/// `pare_data`, `pare_design`, features and apps.
library;

export 'src/extensions/extensions.dart';
export 'src/formatters/formatters.dart';
export 'src/validators/validators.dart';
