/// pare_core — pure domain foundation for PareFood.
///
/// ## Responsibility (PF-DOC-10 §3.2)
/// Owns pure domain models, value objects, exceptions and sealed result types.
///
/// ## Boundaries — must NOT
/// - Import Flutter (`package:flutter/*`)
/// - Perform networking or touch any SDK (Supabase/Dio)
/// - Contain business decisions or pricing logic
///
/// ## Consumers
/// `pare_util`, `pare_data`, `pare_design`, features and apps depend on this
/// package; it depends on nothing internal.
library;

export 'src/exceptions/exceptions.dart';
export 'src/money/money.dart';
export 'src/result/pare_result.dart';
