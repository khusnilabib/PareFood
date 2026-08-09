/// payments_feature — payments for PareFood (PF-DOC-11 §3.1).
///
/// ## Responsibility
/// Payment methods, idempotent charge creation and payment screens. The
/// `CreateCharge` use case enforces a client-generated idempotency key so
/// retried taps never create duplicate charges (NFR-021, FL-R05).
///
/// ## Boundaries — must NOT
/// - Import Supabase/Dio SDKs directly (MO-R02a).
/// - Depend on another feature package (MO-R02d).
library;

export 'src/application/payments_providers.dart';
export 'src/data/payments_repository.dart';
export 'src/domain/payment_method.dart';
export 'src/domain/payment_result.dart';
export 'src/domain/payments_use_cases.dart';
export 'src/presentation/pages/payments_page.dart';
export 'src/presentation/widgets/payment_method_tile.dart';
