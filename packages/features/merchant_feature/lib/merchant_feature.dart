/// merchant_feature — merchant onboarding and restaurant management for
/// PareFood (PF-DOC-11 §3.1).
///
/// ## Responsibility
/// Onboarding wizard (FR-ONB-001), verification status (FR-ONB-002) and
/// restaurant profile management. Layers: `data` defines the
/// [RestaurantRepository] contract with a default `pare_data`-backed adapter;
/// `domain` holds the pure models; `application` owns the providers.
///
/// ## Boundaries — must NOT
/// - Import Supabase/Dio SDKs directly (MO-R02a).
/// - Depend on another feature package (MO-R02d).
library;

export 'src/application/restaurant_providers.dart';
export 'src/data/restaurant_repository.dart';
export 'src/data/supabase_restaurant_repository.dart';
export 'src/domain/restaurant.dart';
export 'src/presentation/pages/merchant_onboarding_page.dart';
export 'src/presentation/pages/merchant_status_page.dart';
