-- ============================================================
-- Ayam Chat - MINIMAL GIFT TABLES (bulletproof)
-- Run in: Supabase Dashboard > SQL Editor > New query > Run
--
-- Creates ONLY the tables needed for the gift flow:
--   store_items      -> THE table the app reads for gifts/frames/effects
--   gift_categories  -> dashboard "الهدايا" category dropdown
--   gifted_items     -> dashboard "الهدايا المرسلة"
--   gift_banner_configs -> dashboard gift banners
--   dm_messages      -> private messages (Overview stats)
--   app_config       -> dashboard config keys
-- plus a read-only `gifts` view for old stats code.
--
-- No RLS is enabled (RLS is OFF by default in Postgres, so after the
-- GRANTs below, anon/authenticated can read and write freely).
-- This file cannot roll back: every statement is independent and
-- guarded with "if not exists".
-- ============================================================

-- ==================== STORE ITEMS ====================
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
alter table public.store_items add column if not exists is_vap boolean default false;
alter table public.store_items add column if not exists is_lucky boolean default false;
alter table public.store_items add column if not exists is_star boolean default false;
alter table public.store_items add column if not exists is_music boolean default false;
alter table public.store_items add column if not exists package_count int default 0;
alter table public.store_items add column if not exists name_key text;
alter table public.store_items add column if not exists photo_key text;
alter table public.store_items add column if not exists default_image text;
alter table public.store_items add column if not exists is_cp_gift boolean default false;
alter table public.store_items add column if not exists cp_gift_duration_hours int default 0;
create index if not exists store_items_type_idx
  on public.store_items (item_type, is_active, "order");

-- ==================== GIFT CATEGORIES ====================
create table if not exists public.gift_categories (
  id text primary key,
  name text default '',
  sort_order int default 0,
  created_at timestamptz default now()
);

-- ==================== GIFTED ITEMS ====================
create table if not exists public.gifted_items (
  id text primary key,
  uid text,
  item_id text,
  item_category text,
  item_name text,
  item_icon text,
  svga_asset text,
  video_asset text,
  sent_by text,
  sent_by_name text,
  sent_at bigint default 0,
  expires_at bigint default 0,
  created_at timestamptz default now()
);

-- ==================== GIFT BANNER CONFIGS ====================
create table if not exists public.gift_banner_configs (
  id text primary key,
  category_id text,
  threshold_coins double precision default 0,
  svga_url text,
  user_r_key text,
  user_l_key text,
  number_key text,
  gift_key text,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ==================== DM MESSAGES ====================
create table if not exists public.dm_messages (
  id uuid primary key default gen_random_uuid(),
  from_user_id text not null,
  to_user_id text not null,
  from_name text,
  to_name text,
  text text,
  is_read boolean default false,
  created_at timestamptz default now()
);
create index if not exists dm_messages_partner_idx
  on public.dm_messages (from_user_id, to_user_id, created_at desc);

-- ==================== APP CONFIG ====================
create table if not exists public.app_config (
  key text primary key,
  value text,
  updated_at timestamptz default now()
);

-- ==================== GIFTS VIEW (read-only, old stats) ====================
create or replace view public.gifts as
  select
    id,
    name,
    price as value,
    image_url as icon_asset,
    svga_url as animation_asset,
    animated,
    "order" as sort_order,
    category as category_id,
    min_level,
    is_active
  from public.store_items
  where item_type = 'gift';

-- ==================== GRANTS (open access for anon/authenticated) ====================
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant select on all sequences in schema public to anon, authenticated;

-- ============================================================
-- DONE. If any statement above printed an error in red, please
-- copy that exact message to me.
-- ============================================================
