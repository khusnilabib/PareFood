/// cart_feature — client-side cart for PareFood (PF-DOC-11 §3.1).
///
/// ## Responsibility
/// Immutable cart snapshot, quantity rules (domain), a Riverpod [CartNotifier]
/// (application) and the cart screen (presentation). Local-first: persistence
/// is behind the [CartStore] contract.
///
/// ## Boundaries — must NOT
/// - Perform networking or import Supabase/Dio SDKs (MO-R02a).
/// - Depend on another feature package (MO-R02d).
library;

export 'src/application/cart_providers.dart';
export 'src/data/cart_store.dart';
export 'src/domain/cart.dart';
export 'src/domain/cart_item.dart';
export 'src/domain/cart_use_cases.dart';
export 'src/presentation/pages/cart_page.dart';
export 'src/presentation/widgets/cart_item_tile.dart';
