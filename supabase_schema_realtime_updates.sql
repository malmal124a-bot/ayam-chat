-- ============================================================
-- REALTIME UPDATES / IN-APP BROADCAST SYSTEM
-- ------------------------------------------------------------
-- Adds a stable "app_broadcasts" table that the admin dashboard
-- writes to, and that every running client subscribes to via
-- Supabase Realtime. Any row inserted/updated here is pushed
-- instantly to all connected users (and reflected on their next
-- app open via a fetch of the latest row).
--
-- Idempotent: every statement is guarded with "if not exists" /
-- "drop policy if exists" so it can be re-run safely.
-- ============================================================

-- 1) Table: app_broadcasts  (live announcements / config-change nudges)
create table if not exists public.app_broadcasts (
  id text primary key default gen_random_uuid()::text,
  type text not null default 'announcement',   -- announcement | update | urgent | config | custom
  title text default '',
  body text default '',
  target text default 'all',                    -- all | specific | level
  payload jsonb default '{}'::jsonb,            -- optional structured data (e.g. table/row changed)
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.app_broadcasts enable row level security;

drop policy if exists "app_broadcasts_select" on public.app_broadcasts;
drop policy if exists "app_broadcasts_insert" on public.app_broadcasts;
drop policy if exists "app_broadcasts_update" on public.app_broadcasts;
drop policy if exists "app_broadcasts_delete" on public.app_broadcasts;
create policy "app_broadcasts_select" on public.app_broadcasts for select using (true);
create policy "app_broadcasts_insert" on public.app_broadcasts for insert with check (true);
create policy "app_broadcasts_update" on public.app_broadcasts for update using (true) with check (true);
create policy "app_broadcasts_delete" on public.app_broadcasts for delete using (true);

-- 2) Make sure all tables the app reacts to are broadcast over Realtime.
--    (safe: adds each only if not already in the publication)
do $$
declare
  t text;
begin
  foreach t in array array[
    'app_broadcasts',
    'app_config',
    'store_items',
    'rooms',
    'users',
    'banners',
    'gift_categories',
    'level_config',
    'vip_config',
    'badges',
    'necklaces',
    'agencies',
    'cps',
    'bds'
  ]
  loop
    if to_regclass('public.' || t) is not null
       and not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
