# payments_feature

Payments for PareFood (PF-DOC-11 §3.1): payment methods, idempotent charge
creation (NFR-021, FL-R05) and a methods screen with four-state handling.

## Layers

- `data/` — `PaymentsRepository` contract. Implementations live in the app
  composition root and delegate to `pare_data` (Dio/Supabase, MO-R02a).
- `domain/` — `PaymentMethod`, `PaymentStatus`, `PaymentResult`,
  `CreateCharge` use case (enforces idempotency key).
- `application/` — `paymentsRepositoryProvider`, `paymentMethodsProvider`.
- `presentation/` — `PaymentsPage` + `PaymentMethodTile`.

## Boundaries

- Never imports Supabase/Dio SDKs directly (MO-R02a).
- Never depends on another feature package (MO-R02d).
- Payments are never retried without an idempotency key (NFR-021, FL-R05).
