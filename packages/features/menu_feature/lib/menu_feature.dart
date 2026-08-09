/// menu_feature — menu management for PareFood (PF-DOC-11 §3.1).
///
/// ## Responsibility
/// Category/item CRUD, availability (out-of-stock) toggling and CSV import
/// (FR-MENU-001/002/003). Layers: `data` defines the [MenuRepository] contract
/// with a default `pare_data`-backed adapter; `domain` holds the pure models;
/// `application` owns the providers.
///
/// ## Boundaries — must NOT
/// - Import Supabase/Dio SDKs directly (MO-R02a).
/// - Depend on another feature package (MO-R02d).
library;

export 'src/application/menu_providers.dart';
export 'src/data/menu_repository.dart';
export 'src/data/supabase_menu_repository.dart';
export 'src/domain/menu_models.dart';
export 'src/presentation/pages/menu_item_edit_page.dart';
export 'src/presentation/pages/menu_management_page.dart';
