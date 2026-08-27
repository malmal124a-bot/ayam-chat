-- ============================================================
-- Ayam Chat - Supabase Schema
-- Run this in: Supabase Dashboard > SQL Editor > New query
-- (It can be run multiple times safely)
-- ============================================================

-- ==================== USERS ====================
create table if not exists public.users (
  auth_uid text primary key,            -- Supabase Auth user id
  numeric_id text unique,                -- 6-digit profile ID
  name text default 'User',
  email text,
  photo_url text,
  gender text default 'Male',
  level int default 1,
  current_xp int default 0,
  vip_level int default 0,
  wealth_level int default 1,
  magic_level int default 1,
  noble_level int default 1,
  wealth_xp int default 0,
  magic_xp int default 0,
  noble_xp int default 0,
  global_score int default 0,
  diamonds int default 0,
  coins int default 0,
  balance double precision default 0,
  total_recharged double precision default 0,
  status text default 'Active',
  is_online boolean default true,
  is_agent boolean default false,
  role text default 'user',
  permissions jsonb default '[]'::jsonb,
  current_room_id text,
  equipped_frame_url text,
  avatar_url text,
  avatar_type text,
  admin_access_expires_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ==================== ROOMS ====================
create table if not exists public.rooms (
  room_id text primary key,             -- User's 6-digit profile ID
  room_name text,
  description text,
  category text,
  owner_id text,
  owner_uid text,
  owner_name text,
  room_cover text,
  participant_count int default 1,
  status text default 'active',
  is_active boolean default true,
  active_mic_count int default 12,
  room_password text,
  background_path text,
  mic_seats jsonb default '{}'::jsonb,
  is_chat_enabled boolean default true,
  all_mics_muted boolean default false,
  created_at timestamptz default now(),
  last_active timestamptz default now(),
  updated_at timestamptz default now()
);

-- ==================== MESSAGES ====================
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  room_id text not null references public.rooms(room_id) on delete cascade,
  sender_name text,
  text text,
  type text default 'text',
  sender_level int default 1,
  target_name text,
  gift_name text,
  gift_count int,
  image_url text,
  created_at timestamptz default now()
);
create index if not exists messages_room_created_idx
  on public.messages (room_id, created_at desc);

-- ==================== PARTICIPANTS ====================
create table if not exists public.participants (
  id uuid primary key default gen_random_uuid(),
  room_id text not null references public.rooms(room_id) on delete cascade,
  uid text,
  user_id text,
  name text,
  profile_pic text,
  level int default 1,
  joined_at timestamptz default now(),
  unique (room_id, uid)
);
create index if not exists participants_room_idx on public.participants (room_id);

-- ==================== DIRECT MESSAGES ====================
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

-- ==================== DAILY CLAIMS ====================
create table if not exists public.daily_claims (
  auth_uid text primary key,
  streak int default 0,
  last_claim timestamptz,
  weekly_claims jsonb default '[false,false,false,false,false,false,false]'::jsonb,
  updated_at timestamptz default now()
);

-- ==================== BANNERS ====================
create table if not exists public.banners (
  id uuid primary key default gen_random_uuid(),
  image_url text,
  title text,
  "order" int default 0,
  created_at timestamptz default now()
);

-- ==================== ROW LEVEL SECURITY ====================
-- NOTE: These are permissive policies for development.
-- For production, restrict them to 'authenticated' only.

alter table public.users enable row level security;
alter table public.rooms enable row level security;
alter table public.messages enable row level security;
alter table public.participants enable row level security;
alter table public.daily_claims enable row level security;
alter table public.banners enable row level security;
alter table public.dm_messages enable row level security;

drop policy if exists "users_select" on public.users;
drop policy if exists "users_insert" on public.users;
drop policy if exists "users_update" on public.users;
create policy "users_select" on public.users for select using (true);
create policy "users_insert" on public.users for insert with check (true);
create policy "users_update" on public.users for update using (true) with check (true);

drop policy if exists "rooms_select" on public.rooms;
drop policy if exists "rooms_insert" on public.rooms;
drop policy if exists "rooms_update" on public.rooms;
drop policy if exists "rooms_delete" on public.rooms;
create policy "rooms_select" on public.rooms for select using (true);
create policy "rooms_insert" on public.rooms for insert with check (true);
create policy "rooms_update" on public.rooms for update using (true) with check (true);
create policy "rooms_delete" on public.rooms for delete using (true);

drop policy if exists "messages_select" on public.messages;
drop policy if exists "messages_insert" on public.messages;
drop policy if exists "messages_delete" on public.messages;
create policy "messages_select" on public.messages for select using (true);
create policy "messages_insert" on public.messages for insert with check (true);
create policy "messages_delete" on public.messages for delete using (true);

drop policy if exists "participants_select" on public.participants;
drop policy if exists "participants_insert" on public.participants;
drop policy if exists "participants_delete" on public.participants;
create policy "participants_select" on public.participants for select using (true);
create policy "participants_insert" on public.participants for insert with check (true);
create policy "participants_delete" on public.participants for delete using (true);

drop policy if exists "daily_claims_select" on public.daily_claims;
drop policy if exists "daily_claims_upsert" on public.daily_claims;
create policy "daily_claims_select" on public.daily_claims for select using (true);
create policy "daily_claims_upsert" on public.daily_claims for insert with check (true);
create policy "daily_claims_update" on public.daily_claims for update using (true) with check (true);

drop policy if exists "banners_select" on public.banners;
drop policy if exists "banners_insert" on public.banners;
create policy "banners_select" on public.banners for select using (true);
create policy "banners_insert" on public.banners for insert with check (true);

drop policy if exists "dm_messages_select" on public.dm_messages;
drop policy if exists "dm_messages_insert" on public.dm_messages;
create policy "dm_messages_select" on public.dm_messages for select using (true);
create policy "dm_messages_insert" on public.dm_messages for insert with check (true);

-- ==================== REALTIME ====================
-- Safe: adds each table to realtime only if not already added
do $$
begin
  foreach t in array array['users', 'rooms', 'messages', 'participants', 'banners', 'dm_messages']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ==================== AGENCIES ====================
create table if not exists public.agencies (
  id text primary key,
  name text default '',
  owner_id text,
  description text default '',
  agency_type text default 'modife',
  members jsonb default '[]'::jsonb,
  total_earnings double precision default 0,
  rating double precision default 5,
  personal_name text,
  national_id text,
  payment_methods jsonb default '[]'::jsonb,
  charging_packages jsonb default '{}'::jsonb,
  charging_logs jsonb default '[]'::jsonb,
  is_activated boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ==================== STORE ITEMS (Gifts / Frames / Entry Effects / Fancy IDs) ====================
-- Unified catalog read by the app's StoreController (frames, entry effects, fancy ids)
-- and GiftController (animated gifts). Managed from the admin dashboard.
-- Image/SVGA assets are uploaded to Cloudinary; this table stores the public URLs.
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

-- ==================== MEDALS ====================
create table if not exists public.medals (
  id text primary key,
  name_key text default '',
  icon_path text default '',
  type text default 'milestone',
  description_key text default '',
  "order" int default 0,
  created_at timestamptz default now()
);

-- RLS for agencies & medals
alter table public.agencies enable row level security;
alter table public.medals enable row level security;
alter table public.store_items enable row level security;

drop policy if exists "agencies_select" on public.agencies;
drop policy if exists "agencies_insert" on public.agencies;
drop policy if exists "agencies_update" on public.agencies;
drop policy if exists "agencies_delete" on public.agencies;
create policy "agencies_select" on public.agencies for select using (true);
create policy "agencies_insert" on public.agencies for insert with check (true);
create policy "agencies_update" on public.agencies for update using (true) with check (true);
create policy "agencies_delete" on public.agencies for delete using (true);

drop policy if exists "medals_select" on public.medals;
drop policy if exists "medals_insert" on public.medals;
create policy "medals_select" on public.medals for select using (true);
create policy "medals_insert" on public.medals for insert with check (true);

drop policy if exists "store_items_select" on public.store_items;
drop policy if exists "store_items_insert" on public.store_items;
drop policy if exists "store_items_update" on public.store_items;
drop policy if exists "store_items_delete" on public.store_items;
create policy "store_items_select" on public.store_items for select using (true);
create policy "store_items_insert" on public.store_items for insert with check (true);
create policy "store_items_update" on public.store_items for update using (true) with check (true);
create policy "store_items_delete" on public.store_items for delete using (true);

-- Realtime for agencies & medals (safe: no error if already added)
do $$
begin
  foreach t in array array['agencies', 'medals', 'store_items']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- Seed default medals (matches lib/repositories/local_medal_repository.dart)
insert into public.medals (id, name_key, icon_path, type, description_key, "order") values
  ('vip_1', 'vip_bronze', 'assets/Asad/medal_vip_1.png', 'vip', 'vip_bronze_desc', 1),
  ('vip_10', 'vip_gold', 'assets/Asad/medal_vip_10.png', 'vip', 'vip_gold_desc', 2),
  ('medal_100m', 'diamond_charger', 'assets/Asad/medal_spender.png', 'milestone', 'diamond_charger_desc', 3),
  ('medal_110m', 'legendary_charger', 'assets/Asad/medal_charity.png', 'milestone', 'legendary_charger_desc', 4),
  ('ramadan_2024', 'ramadan_2024', 'assets/Asad/medal_event_1.png', 'event', 'ramadan_2024_desc', 5)
on conflict (id) do nothing;

-- ==================== SEED ADMIN USER ====================
-- Steps to create an admin (run AFTER a user signs up through the app):
--   1. Open Supabase Dashboard > Authentication > Users, copy the user's UUID.
--   2. Run the SQL below, replacing '<UUID>' with that UUID:
--
-- update public.users
-- set role = 'owner',
--     permissions = '["all"]'::jsonb
-- where auth_uid = '<UUID>';
--
-- The admin panel (lib/admin) checks users.role and users.permissions,
-- so this is all that's needed to grant admin access.
