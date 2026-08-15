-- 0009_dispatch_trigger.sql
-- Sprint 1 loose-end (PF-DOC-14 §3.3 dispatch trigger requirement).
--
-- When `ready-order` (or any path) sets orders.status='ready', a DB trigger POSTs
-- to the `dispatch` Edge Function via pg_net. This is the canonical dispatch
-- invocation per PF-DOC-14 §3.3 note; `ready-order` itself only flips the state
-- and inserts history, avoiding duplicate-dispatch races (BR-JOB-002).
--
-- Prereqs (already in 0001_extensions.sql): pg_net, pg_cron.
--
-- Configuration (set per-environment, NOT in this migration — PF-DOC-19):
--   alter database postgres set app.parefood_functions_base_url to 'https://<ref>.supabase.co';
--   alter database postgres set app.supabase_service_role_key to '<service-role-key>';
-- Both are read at fire time via current_setting(..., true). Local dev defaults
-- to http://localhost:54321 and an empty key (dispatch skeleton does not enforce
-- auth in dev; production MUST set the service role key).

-- ---------------------------------------------------------------------------
-- Base URL helper (overridable per database via GUC).
-- ---------------------------------------------------------------------------
create or replace function public.parefood_functions_base_url()
returns text
language sql
stable
as $$
  select coalesce(
    nullif(current_setting('app.parefood_functions_base_url', true), ''),
    'http://localhost:54321'
  );
$$;

-- ---------------------------------------------------------------------------
-- Dispatch notifier: fires AFTER UPDATE when status transitions INTO 'ready'.
-- Idempotent per transition: only fires when OLD.status <> 'ready'.
-- ---------------------------------------------------------------------------
create or replace function public.notify_dispatch_on_ready()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_url     text;
  v_key     text;
  v_headers jsonb;
begin
  -- Only on the preparing|accepted -> ready transition (PF-DOC-18 §3.3).
  if new.status = 'ready' and coalesce(old.status, '') <> 'ready' then
    v_url := public.parefood_functions_base_url() || '/functions/v1/dispatch';
    v_key := nullif(current_setting('app.supabase_service_role_key', true), '');

    v_headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'X-Idempotency-Key', 'dispatch-' || new.id::text
    );
    if v_key is not null then
      v_headers := v_headers || jsonb_build_object('Authorization', 'Bearer ' || v_key);
    end if;

    -- Fire-and-forget; pg_net retries internally. Failures are picked up by the
    -- cron retry job (BR-DISPATCH-004/005 — to be added in a follow-up migration).
    perform net.http_post(
      url := v_url,
      body := jsonb_build_object('order_id', new.id),
      headers := v_headers,
      timeout_milliseconds := 3000
    );
  end if;
  return new;
end;
$$;

-- Trigger (idempotent: drop if exists then create).
drop trigger if exists orders_dispatch_on_ready on public.orders;
create trigger orders_dispatch_on_ready
  after update on public.orders
  for each row
  execute function public.notify_dispatch_on_ready();

-- ---------------------------------------------------------------------------
-- pg_cron retry: every 2 minutes, re-fire dispatch for orders stuck in 'ready'
-- with no delivery row (BR-DISPATCH-004 widening, BR-DISPATCH-005 cancel at 20m
-- is enforced by a separate job — follow-up). Disabled by default; enable per
-- environment after confirming pg_cron is available on the target.
-- ---------------------------------------------------------------------------
-- do $$
-- begin
--   if not exists (select 1 from cron.job where jobname = 'retry-dispatch') then
--     perform cron.schedule(
--       'retry-dispatch',
--       '*/2 * * * *',
--       $cron$
--         select net.http_post(
--           url := public.parefood_functions_base_url() || '/functions/v1/dispatch',
--           body := (select jsonb_agg(jsonb_build_object('order_id', o.id))
--                    from public.orders o
--                    where o.status = 'ready'
--                      and not exists (select 1 from public.deliveries d where d.order_id = o.id)
--                    limit 50),
--           headers := jsonb_build_object('Content-Type','application/json')
--         );
--       $cron$
--     );
--   end if;
-- end $$;

-- end migration
