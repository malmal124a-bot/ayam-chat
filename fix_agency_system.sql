-- ============================================================
-- Ayam Chat - AGENCY SYSTEM REPAIR (idempotent / safe to re-run)
-- ------------------------------------------------------------
-- Fixes the conflicts introduced by the uuid->text migration:
--   * host_agency_members.agency_id / user_id  -> text (was uuid)
--   * host_agency_join_requests.agency_id / user_id -> text (was uuid)
--   * Re-creates the user_id FKs the Flutter app relies on
--     (host_agency_members_user_id_fkey,
--      host_agency_join_requests_user_id_fkey -> users(auth_uid))
--   * Adds any missing columns the app reads/writes.
--   * Ensures agencies.photo_url exists.
-- Run in: Supabase SQL Editor  (run AFTER MASTER_SETUP.sql)
-- ============================================================

-- ---------- 1. host_agency_members ----------
do $$ begin
  if not exists (
    select 1 from information_schema.tables
    where table_schema='public' and table_name='host_agency_members'
  ) then
    create table public.host_agency_members (
      id uuid primary key default gen_random_uuid(),
      agency_id text not null,
      user_id text not null,
      role text default 'host',
      status text default 'active',
      joined_at timestamptz default now(),
      diamonds_earned_cumulative int default 0,
      diamonds_earned_monthly int default 0,
      diamonds_balance int default 0,
      trial_ends_at timestamptz
    );
  end if;
end $$;

do $$ begin
  if exists (
    select 1 from information_schema.columns
    where table_name='host_agency_members' and column_name='agency_id' and udt_name='uuid'
  ) then
    alter table public.host_agency_members drop constraint if exists host_agency_members_agency_id_fkey;
    alter table public.host_agency_members alter column agency_id type text using agency_id::text;
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_name='host_agency_members' and column_name='user_id' and udt_name='uuid'
  ) then
    alter table public.host_agency_members drop constraint if exists host_agency_members_user_id_fkey;
    alter table public.host_agency_members alter column user_id type text using user_id::text;
  end if;
end $$;

do $$ begin
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='role') then
    alter table public.host_agency_members add column role text default 'host'; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='status') then
    alter table public.host_agency_members add column status text default 'active'; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='joined_at') then
    alter table public.host_agency_members add column joined_at timestamptz default now(); end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='diamonds_earned_cumulative') then
    alter table public.host_agency_members add column diamonds_earned_cumulative int default 0; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='diamonds_earned_monthly') then
    alter table public.host_agency_members add column diamonds_earned_monthly int default 0; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='diamonds_balance') then
    alter table public.host_agency_members add column diamonds_balance int default 0; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='trial_ends_at') then
    alter table public.host_agency_members add column trial_ends_at timestamptz; end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_constraint where conname='host_agency_members_user_id_fkey') then
    alter table public.host_agency_members
      add constraint host_agency_members_user_id_fkey
      foreign key (user_id) references public.users(auth_uid) on delete cascade;
  end if;
end $$;

-- ---------- 2. host_agency_join_requests ----------
do $$ begin
  if not exists (
    select 1 from information_schema.tables
    where table_schema='public' and table_name='host_agency_join_requests'
  ) then
    create table public.host_agency_join_requests (
      id uuid primary key default gen_random_uuid(),
      agency_id text not null,
      user_id text not null,
      status text default 'pending',
      message text default '',
      created_at timestamptz default now()
    );
  end if;
end $$;

do $$ begin
  if exists (
    select 1 from information_schema.columns
    where table_name='host_agency_join_requests' and column_name='agency_id' and udt_name='uuid'
  ) then
    alter table public.host_agency_join_requests drop constraint if exists host_agency_join_requests_agency_id_fkey;
    alter table public.host_agency_join_requests alter column agency_id type text using agency_id::text;
  end if;
  if exists (
    select 1 from information_schema.columns
    where table_name='host_agency_join_requests' and column_name='user_id' and udt_name='uuid'
  ) then
    alter table public.host_agency_join_requests drop constraint if exists host_agency_join_requests_user_id_fkey;
    alter table public.host_agency_join_requests alter column user_id type text using user_id::text;
  end if;
end $$;

do $$ begin
  if not exists (select 1 from information_schema.columns where table_name='host_agency_join_requests' and column_name='status') then
    alter table public.host_agency_join_requests add column status text default 'pending'; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_join_requests' and column_name='message') then
    alter table public.host_agency_join_requests add column message text default ''; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_join_requests' and column_name='created_at') then
    alter table public.host_agency_join_requests add column created_at timestamptz default now(); end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_constraint where conname='host_agency_join_requests_user_id_fkey') then
    alter table public.host_agency_join_requests
      add constraint host_agency_join_requests_user_id_fkey
      foreign key (user_id) references public.users(auth_uid) on delete cascade;
  end if;
end $$;

-- ---------- 3. agencies.photo_url ----------
do $$ begin
  if not exists (
    select 1 from information_schema.columns
    where table_name='agencies' and column_name='photo_url'
  ) then
    alter table public.agencies add column photo_url text default '';
  end if;
end $$;

-- ---------- 4. RLS (permissive, so the app's direct writes work) ----------
alter table public.host_agency_members enable row level security;
alter table public.host_agency_join_requests enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where policyname='ham_select' and tablename='host_agency_members') then
    create policy ham_select on public.host_agency_members for select using (true); end if;
  if not exists (select 1 from pg_policies where policyname='ham_insert' and tablename='host_agency_members') then
    create policy ham_insert on public.host_agency_members for insert with check (true); end if;
  if not exists (select 1 from pg_policies where policyname='ham_update' and tablename='host_agency_members') then
    create policy ham_update on public.host_agency_members for update using (true) with check (true); end if;
  if not exists (select 1 from pg_policies where policyname='ham_delete' and tablename='host_agency_members') then
    create policy ham_delete on public.host_agency_members for delete using (true); end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_policies where policyname='hajr_select' and tablename='host_agency_join_requests') then
    create policy hajr_select on public.host_agency_join_requests for select using (true); end if;
  if not exists (select 1 from pg_policies where policyname='hajr_insert' and tablename='host_agency_join_requests') then
    create policy hajr_insert on public.host_agency_join_requests for insert with check (true); end if;
  if not exists (select 1 from pg_policies where policyname='hajr_update' and tablename='host_agency_join_requests') then
    create policy hajr_update on public.host_agency_join_requests for update using (true) with check (true); end if;
  if not exists (select 1 from pg_policies where policyname='hajr_delete' and tablename='host_agency_join_requests') then
    create policy hajr_delete on public.host_agency_join_requests for delete using (true); end if;
end $$;

-- ---------- 5. Realtime ----------
do $$ begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='host_agency_members'
  ) then
    execute 'alter publication supabase_realtime add table public.host_agency_members';
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='host_agency_join_requests'
  ) then
    execute 'alter publication supabase_realtime add table public.host_agency_join_requests';
  end if;
end $$;

-- Done.
