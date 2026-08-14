# cart_feature

Cart management feature for PareFood customer app (Sprint 2).

## Responsibility

Implements FR-CART-001..006 from PF-DOC-07:
- Add/update/remove cart items with options and quantity
- Single-restaurant cart constraint
- Fee breakdown (subtotal + delivery + service + promo)
- Address selection and promo validation
- Delivery time estimates

## Architecture

Follows PF-DOC-11 layering:

```
lib/
├── domain/           # Pure use cases (AddToCart, RemoveItem, etc.)
├── data/             # Repository contracts (CartRepository)
├── application/      # Riverpod providers (cartProvider, feeBreakdownProvider)
└── presentation/     # Pages (CartPage, CheckoutPage) + widgets
```

## Testing

Unit tests for use cases (domain logic) mirror BR-PRICE rules from PF-DOC-18:

```bash
flutter test
```

## Integration

Wired in `apps/parefood` composition root:

```dart
ProviderScope(
  overrides: [
    cartRepositoryProvider.overrideWithValue(CartRepositoryDrift()),
  ],
  child: app,
)
```
