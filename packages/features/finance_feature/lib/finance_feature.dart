/// finance_feature — finance ops for PareFood (PF-DOC-11 §3.5).
///
/// ## Responsibility
/// Settlements (restaurant T+7), payouts (driver daily), reconciliation
/// (COD vs remittances) and platform analytics KPIs. Admin role only.
///
/// ## Boundaries — must NOT
/// - Import Supabase/Dio SDKs directly (MO-R02a).
/// - Depend on another feature package (MO-R02d).
library;

export 'src/application/finance_providers.dart';
export 'src/data/finance_repository.dart';
export 'src/data/supabase_finance_repository.dart';
export 'src/domain/payout.dart';
export 'src/domain/reconciliation_report.dart';
export 'src/domain/settlement.dart';
export 'src/presentation/pages/analytics_dashboard_page.dart';
export 'src/presentation/pages/payouts_page.dart';
export 'src/presentation/pages/reconciliation_page.dart';
export 'src/presentation/pages/settlements_page.dart';
