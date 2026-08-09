-- 0001_extensions.sql
-- Sprint 1 (PF-SPRINT-01, task B1)
-- Enable required Postgres extensions and shared helpers (PF-DOC-13 §3.1, PF-DOC-12 §3.8).

create extension if not exists pgcrypto;
create extension if not exists postgis;
create extension if not exists pg_trgm;
create extension if not exists pg_net;
create extension if not exists pg_cron;

-- Shared updated_at trigger function (PF-DOC-13 conventions: timestamps default + trigger).
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Role mirror helper: mirrors profiles.role into auth.users.app_metadata['role']
-- so the client JWT carries the role claim (PF-DOC-12 §3.2, PF-DOC-19 §3.2).
create or replace function public.sync_role_claim()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update auth.users
     set raw_app_meta_data =
           jsonb_set(
             coalesce(raw_app_meta_data, '{}'::jsonb),
             '{role}',
             to_jsonb(new.role)
           )
   where id = new.id;
  return new;
end;
$$;

-- Trigger the role sync after profile role changes. The trigger itself is
-- created in migration 0002, where the profiles table exists.
