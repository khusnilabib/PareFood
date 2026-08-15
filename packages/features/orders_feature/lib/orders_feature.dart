/// orders_feature — order lifecycle for PareFood (PF-DOC-11 §3.1).
///
/// Shared by all four apps. Role-scoped repository queries (customer / merchant
/// / driver / admin) and presentation pages for each app's order view. Write
/// actions (accept, cancel, pickup, deliver) are callback-injected by the app
/// composition root so this package never imports an Edge Function client
/// (MO-R02d).
///
/// ## Boundaries — must NOT
/// - Import Supabase/Dio SDKs directly (MO-R02a).
/// - Depend on another feature package (MO-R02d).
library;

export 'src/application/orders_providers.dart';
export 'src/data/orders_repository.dart';
export 'src/data/supabase_orders_repository.dart';
export 'src/domain/order_detail.dart';
export 'src/domain/order_status.dart';
export 'src/domain/order_summary.dart';
export 'src/domain/orders_use_cases.dart';
export 'src/presentation/order_status_view.dart';
export 'src/presentation/pages/admin_order_board_page.dart';
export 'src/presentation/pages/driver_jobs_page.dart';
export 'src/presentation/pages/incoming_orders_page.dart';
export 'src/presentation/pages/order_detail_page.dart';
export 'src/presentation/pages/orders_page.dart';
export 'src/presentation/widgets/order_card.dart';
