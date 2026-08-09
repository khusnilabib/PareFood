/// orders_feature — order list and tracking for PareFood (PF-DOC-11 §3.1).
///
/// ## Responsibility
/// Order summaries, lifecycle status mapping (to `PfStatusBadge`) and an
/// `OrdersPage` covering loading/error/empty/content (FL-R07).
///
/// ## Boundaries — must NOT
/// - Import Supabase/Dio SDKs directly (MO-R02a).
/// - Depend on another feature package (MO-R02d).
library;

export 'src/application/orders_providers.dart';
export 'src/data/orders_repository.dart';
export 'src/domain/order_status.dart';
export 'src/domain/order_summary.dart';
export 'src/domain/orders_use_cases.dart';
export 'src/presentation/pages/orders_page.dart';
export 'src/presentation/widgets/order_card.dart';
