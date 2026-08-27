-- ============================================================
-- Ayam Chat - FULL PROVISIONING SCRIPT
-- Run this in: Supabase Dashboard > SQL Editor > New query > Run
-- Safe to run multiple times (idempotent).
--
-- Creates EVERY table the Flutter app + admin dashboard use:
--   app tables:    users, rooms, messages, participants, dm_messages,
--                  daily_claims, banners, agencies, store_items, medals
--   dashboard:     app_config, level_config, vip_config, badges, necklaces,
--                  user_vips, admin_users, admin_action_logs, dashboard_bans,
--                  sent_gifts, unions, cps, bds, cp_gifts, cp_cars, cp_settings,
--                  signin_rewards, commission_settings, host_agencies,
--                  host_agency_members, host_agency_join_requests,
--                  host_milestones, agency_diamond_ledger,
--                  agency_withdrawal_requests, bug_reports, app_assets,
--                  gift_banner_configs, gift_categories, gifted_items
-- ============================================================

-- ==================== USERS ====================
create table if not exists public.users (
  auth_uid text primary key,
  numeric_id text unique,
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
  room_id text primary key,
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

-- ==================== STORE ITEMS ====================
-- THE table the app reads (CatalogService -> StoreController / GiftController).
-- Extra columns below keep the dashboard Gifts page fields round-tripping.
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

-- ==================== APP CONFIG (key-value) ====================
create table if not exists public.app_config (
  key text primary key,
  value text,
  updated_at timestamptz default now()
);

-- ==================== LEVEL CONFIG ====================
create table if not exists public.level_config (
  type text default 'level',
  level int default 1,
  name text,
  name_ar text,
  name_en text,
  title_ar text,
  title_en text,
  description_ar text,
  description_en text,
  icon_url text,
  svga_url text,
  image_url text,
  bg_url text,
  color text,
  xp_min bigint default 0,
  xp_max bigint default 0,
  min_xp bigint default 0,
  max_xp bigint default 0,
  value int default 0,
  rewards jsonb default '[]'::jsonb,
  is_active boolean default true,
  sort_order int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  primary key (type, level)
);

-- ==================== VIP CONFIG ====================
create table if not exists public.vip_config (
  tier int primary key,
  name text default '',
  min_spend double precision default 0,
  price double precision default 0,
  color text,
  image_url text,
  bg_url text,
  logo_url text,
  medal_url text,
  medal_img_url text,
  benefits jsonb default '[]'::jsonb,
  headwear_url text,
  headwear_img_url text,
  entrance_url text,
  entrance_img_url text,
  bubble_url text,
  bubble_img_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ==================== BADGES ====================
create table if not exists public.badges (
  id text primary key,
  name text default '',
  name_ar text,
  name_en text,
  icon_asset text,
  description text,
  description_ar text,
  description_en text,
  unlock_condition text,
  svga_url text,
  image_url text,
  sort_order int default 0,
  is_active boolean default true,
  type text default 'admin',
  level_type text default 'wealth',
  level_number int,
  created_at timestamptz default now()
);

-- ==================== NECKLACES ====================
create table if not exists public.necklaces (
  id text primary key,
  name text default '',
  name_ar text,
  name_en text,
  description_ar text,
  description_en text,
  svga_url text,
  image_url text,
  price double precision default 0,
  sort_order int default 0,
  is_active boolean default true,
  type text default 'admin',
  required_recharge_level int default 0,
  created_at timestamptz default now()
);

-- ==================== USER VIPS ====================
create table if not exists public.user_vips (
  id uuid primary key default gen_random_uuid(),
  uid text references public.users(auth_uid) on delete cascade,
  tier int default 1,
  purchased_at timestamptz default now(),
  expires_at timestamptz,
  gifted_by text,
  created_at timestamptz default now()
);

-- ==================== ADMIN USERS ====================
create table if not exists public.admin_users (
  uid text primary key,
  email text,
  display_name text,
  role text default 'moderator',
  permissions jsonb default '{}'::jsonb,
  photo_url text,
  is_active boolean default true,
  created_by text,
  created_at timestamptz default now()
);

-- ==================== ADMIN ACTION LOGS ====================
create table if not exists public.admin_action_logs (
  id uuid primary key default gen_random_uuid(),
  admin_uid text,
  admin_name text,
  action text,
  target_type text,
  target_id text,
  details jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- ==================== DASHBOARD BANS ====================
create table if not exists public.dashboard_bans (
  uid text primary key,
  email text,
  reason text,
  banned_by text,
  banned_at timestamptz default now()
);

-- ==================== SENT GIFTS ====================
create table if not exists public.sent_gifts (
  id uuid primary key default gen_random_uuid(),
  gift_id text,
  sender_id text,
  sender_name text,
  sender_photo_url text,
  receiver_id text,
  receiver_name text,
  room_id text,
  value double precision default 0,
  count int default 1,
  timestamp bigint default 0,
  created_at timestamptz default now()
);

-- ==================== UNIONS ====================
create table if not exists public.unions (
  id text primary key,
  name text default '',
  description text default '',
  creator_id text,
  creator_name text,
  logo_url text,
  member_count int default 0,
  level int default 1,
  created_at timestamptz default now()
);

-- ==================== CPS / BDS ====================
create table if not exists public.cps (
  id text primary key,
  name text default '',
  name_ar text,
  name_en text,
  avatar_url text,
  status text default 'active',
  created_at timestamptz default now()
);
create table if not exists public.bds (
  id text primary key,
  name text default '',
  name_ar text,
  name_en text,
  avatar_url text,
  status text default 'active',
  created_at timestamptz default now()
);

-- ==================== CP FEATURES ====================
create table if not exists public.cp_gifts (
  id text primary key,
  name text default '',
  name_ar text,
  name_en text,
  icon_url text,
  svga_url text,
  value double precision default 0,
  sort_order int default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);
create table if not exists public.cp_cars (
  id text primary key,
  name text default '',
  name_ar text,
  name_en text,
  svga_url text,
  thumbnail_url text,
  sort_order int default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);
create table if not exists public.cp_settings (
  key text primary key,
  value text,
  updated_at timestamptz default now()
);

-- ==================== SIGN-IN REWARDS ====================
create table if not exists public.signin_rewards (
  id text primary key,
  day_number int default 1,
  label_ar text,
  label_en text,
  icon_url text,
  svga_url text,
  value double precision default 0,
  value_type text default 'coins',
  gift_id text,
  is_double boolean default false,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ==================== COMMISSION SETTINGS ====================
create table if not exists public.commission_settings (
  id text primary key,
  key text unique,
  value double precision default 0,
  updated_at timestamptz default now()
);

-- ==================== HOST AGENCIES ====================
create table if not exists public.host_agencies (
  id uuid primary key default gen_random_uuid(),
  name text default '',
  owner_id text,
  commission_rate double precision default 0,
  specialty text,
  member_count int default 0,
  is_active boolean default true,
  total_diamonds_earned double precision default 0,
  monthly_diamonds double precision default 0,
  tier text default 'bronze',
  photo_url text,
  country text,
  is_hall_of_fame boolean default false,
  description text,
  phone text,
  created_at timestamptz default now()
);
create table if not exists public.host_agency_members (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid references public.host_agencies(id) on delete cascade,
  user_id text,
  role text default 'host',
  status text default 'active',
  joined_at timestamptz default now()
);
create table if not exists public.host_agency_join_requests (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid references public.host_agencies(id) on delete cascade,
  user_id text,
  status text default 'pending',
  created_at timestamptz default now()
);
create table if not exists public.host_milestones (
  id text primary key,
  name text,
  name_ar text,
  target double precision default 0,
  reward_type text default 'coins',
  reward_value double precision default 0,
  sort_order int default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);
create table if not exists public.agency_diamond_ledger (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid references public.host_agencies(id) on delete cascade,
  user_id text,
  amount double precision default 0,
  note text,
  created_at timestamptz default now()
);
create table if not exists public.agency_withdrawal_requests (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid references public.host_agencies(id) on delete cascade,
  user_id text,
  amount double precision default 0,
  status text default 'pending',
  created_at timestamptz default now()
);

-- ==================== BUG REPORTS ====================
create table if not exists public.bug_reports (
  id uuid primary key default gen_random_uuid(),
  user_id text,
  message text,
  page text,
  stack text,
  created_at timestamptz default now()
);

-- ==================== APP ASSETS ====================
create table if not exists public.app_assets (
  id uuid primary key default gen_random_uuid(),
  key text unique,
  name text default '',
  type text default '',
  category text,
  local_path text,
  remote_url text,
  sort_order int default 0,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
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

-- ==================== GIFTS VIEW ====================
-- Legacy compatibility: the dashboard Overview/Stats used to read gifts.value.
-- This view exposes store_items (gift rows) in that old shape.
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

-- ==================== ROW LEVEL SECURITY ====================
-- Permissive policies (development): anon + authenticated can do everything.
do $$
declare t text; p text; pol text;
begin
  foreach t in array array[
    'users','rooms','messages','participants','dm_messages','daily_claims',
    'banners','agencies','store_items','medals','app_config','level_config',
    'vip_config','badges','necklaces','user_vips','admin_users',
    'admin_action_logs','dashboard_bans','sent_gifts','unions','cps','bds',
    'cp_gifts','cp_cars','cp_settings','signin_rewards','commission_settings',
    'host_agencies','host_agency_members','host_agency_join_requests',
    'host_milestones','agency_diamond_ledger','agency_withdrawal_requests',
    'bug_reports','app_assets','gift_banner_configs','gift_categories',
    'gifted_items'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    foreach p in array array['select','insert','update','delete']
    loop
      pol := t || '_' || p;
      execute format('drop policy if exists %I on public.%I', pol, t);
      if p = 'select' then
        execute format('create policy %I on public.%I for select using (true)', pol, t);
      elsif p = 'insert' then
        execute format('create policy %I on public.%I for insert with check (true)', pol, t);
      elsif p = 'update' then
        execute format('create policy %I on public.%I for update using (true) with check (true)', pol, t);
      else
        execute format('create policy %I on public.%I for delete using (true)', pol, t);
      end if;
    end loop;
  end loop;
end $$;

-- ==================== GRANTS ====================
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant select on all sequences in schema public to anon, authenticated;
grant all on all functions in schema public to anon, authenticated;

-- ==================== REALTIME ====================
do $$
declare t text;
begin
  foreach t in array array[
    'users','rooms','messages','participants','dm_messages','daily_claims',
    'banners','agencies','store_items','medals','app_config','level_config',
    'vip_config','badges','necklaces','user_vips','admin_users',
    'admin_action_logs','dashboard_bans','sent_gifts','unions','cps','bds',
    'cp_gifts','cp_cars','cp_settings','signin_rewards','commission_settings',
    'host_agencies','host_agency_members','host_agency_join_requests',
    'host_milestones','agency_diamond_ledger','agency_withdrawal_requests',
    'bug_reports','app_assets','gift_banner_configs','gift_categories',
    'gifted_items'
  ]
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ==================== SEED DEFAULT MEDALS ====================
insert into public.medals (id, name_key, icon_path, type, description_key, "order") values
  ('vip_1', 'vip_bronze', 'assets/Asad/medal_vip_1.png', 'vip', 'vip_bronze_desc', 1),
  ('vip_10', 'vip_gold', 'assets/Asad/medal_vip_10.png', 'vip', 'vip_gold_desc', 2),
  ('medal_100m', 'diamond_charger', 'assets/Asad/medal_spender.png', 'milestone', 'diamond_charger_desc', 3),
  ('medal_110m', 'legendary_charger', 'assets/Asad/medal_charity.png', 'milestone', 'legendary_charger_desc', 4),
  ('ramadan_2024', 'ramadan_2024', 'assets/Asad/medal_event_1.png', 'event', 'ramadan_2024_desc', 5)
on conflict (id) do nothing;

-- ============================================================
-- DONE. After running:
--   • All app + dashboard tables exist with open RLS + realtime.
--   • Adding a gift in dashboard "الهدايا" writes a store_items row
--     (item_type='gift') that the app loads via CatalogService.
-- ============================================================
