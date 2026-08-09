/// discovery_feature — restaurant discovery for PareFood (PF-DOC-11 §3.1).
///
/// ## Responsibility
/// Nearest-first restaurant list and restaurant detail with menu (FR-DISC-001,
/// FR-DISC-004). Sprint 1 ships the read-side only. Layers: `data` defines the
/// [DiscoveryRepository] contract with a default `pare_data`-backed adapter;
/// `domain` holds the pure models; `application` owns the providers.
///
/// ## Boundaries — must NOT
/// - Import Supabase/Dio SDKs directly (MO-R02a).
/// - Depend on another feature package (MO-R02d).
library;

export 'src/application/discovery_providers.dart';
export 'src/data/discovery_repository.dart';
export 'src/data/supabase_discovery_repository.dart';
export 'src/domain/discovery_models.dart';
export 'src/presentation/pages/discovery_page.dart';
export 'src/presentation/pages/restaurant_detail_page.dart';
