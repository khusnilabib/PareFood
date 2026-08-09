-- 0006_storage.sql
-- Sprint 1 (PF-SPRINT-01, task B6)
-- Storage buckets + policies (PF-DOC-12 §3.4, SUP-R05 path structure).

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('merchant-docs', 'merchant-docs', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- product-images: public read; restaurant owner (business) write for their
-- restaurant; admin write. Path: <restaurant_id>/<entity>/<id>.<ext> (SUP-R05).
drop policy if exists product_images_select on storage.objects;
create policy product_images_select on storage.objects
  for select using (bucket_id = 'product-images');

drop policy if exists product_images_insert on storage.objects;
create policy product_images_insert on storage.objects
  for insert with check (
    bucket_id = 'product-images'
    and (
      auth.jwt() ->> 'role' = 'admin'
      or public.is_restaurant_owner(
           (regexp_match(name, '^([^/]+)/'))[1]::uuid
         )
    )
  );

drop policy if exists product_images_update on storage.objects;
create policy product_images_update on storage.objects
  for update using (
    bucket_id = 'product-images'
    and (
      auth.jwt() ->> 'role' = 'admin'
      or public.is_restaurant_owner(
           (regexp_match(name, '^([^/]+)/'))[1]::uuid
         )
    )
  );

-- merchant-docs: private; owner (business) writes their own; admin all.
-- Path: <user_id>/<doc_type>/<id>.<ext>.
drop policy if exists merchant_docs_select on storage.objects;
create policy merchant_docs_select on storage.objects
  for select using (
    bucket_id = 'merchant-docs'
    and (
      auth.jwt() ->> 'role' = 'admin'
      or (regexp_match(name, '^([^/]+)/'))[1]::uuid = auth.uid()
    )
  );

drop policy if exists merchant_docs_insert on storage.objects;
create policy merchant_docs_insert on storage.objects
  for insert with check (
    bucket_id = 'merchant-docs'
    and (
      auth.jwt() ->> 'role' = 'admin'
      or (regexp_match(name, '^([^/]+)/'))[1]::uuid = auth.uid()
    )
  );

drop policy if exists merchant_docs_update on storage.objects;
create policy merchant_docs_update on storage.objects
  for update using (
    bucket_id = 'merchant-docs'
    and (
      auth.jwt() ->> 'role' = 'admin'
      or (regexp_match(name, '^([^/]+)/'))[1]::uuid = auth.uid()
    )
  );

-- avatars: public read; owner writes. Path: <user_id>/<id>.<ext>.
drop policy if exists avatars_select on storage.objects;
create policy avatars_select on storage.objects
  for select using (bucket_id = 'avatars');

drop policy if exists avatars_insert on storage.objects;
create policy avatars_insert on storage.objects
  for insert with check (
    bucket_id = 'avatars'
    and (
      auth.jwt() ->> 'role' = 'admin'
      or (regexp_match(name, '^([^/]+)/'))[1]::uuid = auth.uid()
    )
  );

drop policy if exists avatars_update on storage.objects;
create policy avatars_update on storage.objects
  for update using (
    bucket_id = 'avatars'
    and (
      auth.jwt() ->> 'role' = 'admin'
      or (regexp_match(name, '^([^/]+)/'))[1]::uuid = auth.uid()
    )
  );
