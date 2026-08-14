/// cart_feature — cart management for PareFood (PF-DOC-11 §3.1).
///
/// Responsibility: Add/update/remove cart items, checkout with fee breakdown,
/// address selection, promo validation per FR-CART-001..006.
library;

export 'src/application/cart_providers.dart';
export 'src/data/cart_repository.dart';
export 'src/domain/cart.dart';
export 'src/domain/cart_item.dart';
export 'src/presentation/pages/cart_page.dart';
