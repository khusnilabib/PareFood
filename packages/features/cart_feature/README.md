# cart_feature

Client-side cart for PareFood (PF-DOC-11 §3.1): immutable cart snapshot held
by `cartProvider` (Notifier), quantity rules in the domain layer, cart screen
with empty-state handling (FL-R07).

## Layers

- `data/` — `CartStore` contract for local persistence (offline strategy,
  PF-DOC-11 §3.4; drift implementation lands later).
- `domain/` — `Cart`, `CartItem`, `AddToCart` use case (pure Dart).
- `application/` — `cartProvider` (Notifier), `cartStoreProvider`.
- `presentation/` — `CartPage` + `CartItemTile`.

## Boundaries

- No networking; never depends on another feature package (MO-R02d).
- Presentation never imports `data`; it consumes providers only (PF-DOC-11 §3.1).
