# orders_feature

Order list and tracking for PareFood (PF-DOC-11 §3.1): order summaries,
status mapping to `PfStatusBadge` and an `OrdersPage` covering all four states
(FL-R07).

## Layers

- `data/` — `OrdersRepository` contract. Implementations live in the app
  composition root and delegate to `pare_data` (Dio/Supabase, MO-R02a).
- `domain/` — `OrderStatus`, `OrderSummary`, `FetchActiveOrders` use case.
- `application/` — `ordersRepositoryProvider`, `activeOrdersProvider`.
- `presentation/` — `OrdersPage` + `OrderCard`.

## Boundaries

- Never imports Supabase/Dio SDKs directly (MO-R02a).
- Never depends on another feature package (MO-R02d).
- Presentation never imports `data`; it consumes providers only (PF-DOC-11 §3.1).
