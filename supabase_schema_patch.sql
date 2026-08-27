-- ====================================================================
-- PATCH: إضافة الجداول الناقصة فقط (store_items + dm_messages)
-- الصق هذا الكود في Supabase Dashboard > SQL Editor > Run
-- آمن لإعادة التشغيل (if not exists)
-- ====================================================================

-- ==================== DM MESSAGES ====================
create table if not exists public.dm_messages (
  id uuid primary key default gen_random_uuid(),
  from_user_id text not null,          -- sender 6-digit numeric id
  to_user_id text not null,            -- receiver 6-digit numeric id
  from_name text,
  to_name text,
  text text,
  is_read boolean default false,
  created_at timestamptz default now()
);
create index if not exists dm_messages_partner_idx
  on public.dm_messages (from_user_id, to_user_id, created_at desc);

-- ==================== STORE ITEMS (Gifts / Frames / Entry Effects / Fancy IDs) ====================
create table if not exists public.store_items (
  id text primary key,
  name text not null default '',
  category text default '',
  item_type text default 'gift',        -- gift | frame | entryEffect | fancyId
  price double precision default 0,
  image_url text,
  svga_url text,
  animated boolean default false,
  min_level int default 1,
  is_active boolean default true,
  "order" int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists store_items_type_idx
  on public.store_items (item_type, is_active, "order");

-- ==================== ROW LEVEL SECURITY ====================
alter table public.dm_messages enable row level security;
alter table public.store_items enable row level security;

drop policy if exists "dm_messages_select" on public.dm_messages;
drop policy if exists "dm_messages_insert" on public.dm_messages;
create policy "dm_messages_select" on public.dm_messages for select using (true);
create policy "dm_messages_insert" on public.dm_messages for insert with check (true);

drop policy if exists "store_items_select" on public.store_items;
drop policy if exists "store_items_insert" on public.store_items;
drop policy if exists "store_items_update" on public.store_items;
drop policy if exists "store_items_delete" on public.store_items;
create policy "store_items_select" on public.store_items for select using (true);
create policy "store_items_insert" on public.store_items for insert with check (true);
create policy "store_items_update" on public.store_items for update using (true) with check (true);
create policy "store_items_delete" on public.store_items for delete using (true);

-- ==================== REALTIME ====================
do $$
begin
  foreach t in array array['dm_messages', 'store_items']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
