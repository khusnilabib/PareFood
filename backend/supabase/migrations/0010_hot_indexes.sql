-- 0010_hot_indexes.sql
-- Sprint 2 (PF-DOC-13 §5.2, sprint-01-migration-audit §4).
-- Adds the 7 critical composite/GIN indexes the audit identified as missing.
-- These back the hot read paths: live order board, idempotency lookup,
-- customer history, menu/search, eligible-driver scan, wallet reads.

-- 1. Live order board + BR-ACCEPT-001 scan (orders in 'placed' within 120s).
create index if not exists idx_orders_status_placed
  on public.orders (status, placed_at);

-- 2. Idempotency replay lookup (API-R02, NFR-021).
create index if not exists idx_orders_idempotency
  on public.orders (idempotency_key)
  where idempotency_key is not null;

-- 3. Customer order history pagination (FR-ORDER-009).
create index if not exists idx_orders_customer_placed
  on public.orders (customer_id, placed_at desc);

-- 4. Menu item search by name (FR-DISC-002, NFR-004 sub-second).
--    pg_trgm GIN supports ilike/trigram search; extension enabled in 0001.
create index if not exists idx_menu_items_name_trgm
  on public.menu_items using gin (name gin_trgm_ops);

-- 5. Search documents name + available filter (FR-DISC-002).
create index if not exists idx_search_documents_name_trgm
  on public.search_documents using gin (name gin_trgm_ops);

-- 6. Eligible-driver scan for dispatch (BR-DISPATCH-002: online, in radius,
--    not on active job). The online flag is the hot filter.
create index if not exists idx_driver_locations_active
  on public.driver_locations (online, updated_at desc);

-- 7. Wallet transaction reads (earnings, settlements, reconciliation).
create index if not exists idx_wallet_tx_created
  on public.wallet_transactions (wallet_id, created_at desc);

-- end migration
