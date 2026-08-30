-- ============================================================
-- Ayam Chat - AGENCY EARNINGS / LEVEL / WITHDRAW / LEAVE / TRANSFER
-- Idempotent & safe to re-run. Run in Supabase SQL Editor AFTER
-- MASTER_SETUP.sql and fix_agency_system.sql.
--
-- Adds:
--   1. Per-member level/target/period columns on host_agency_members
--   2. agency_withdrawal_requests (with proof screenshot flow)
--   3. agency_leave_requests (host -> agent approval)
--   4. agency_transfer_requests (host -> shipping agent approval)
--   5. host_profit_levels.target (per-level target from the board)
--   6. RLS (permissive) + realtime + grants
-- ============================================================

-- ---------- 1. host_agency_members: level / target / period ----------
do $$ begin
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='target') then
    alter table public.host_agency_members add column target int default 5000; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='level') then
    alter table public.host_agency_members add column level int default 1; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='period_type') then
    alter table public.host_agency_members add column period_type text default 'weekly'; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='period_start') then
    alter table public.host_agency_members add column period_start timestamptz; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='period_end') then
    alter table public.host_agency_members add column period_end timestamptz; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='shipping_agent_id') then
    alter table public.host_agency_members add column shipping_agent_id text; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_agency_members' and column_name='shipping_agent_name') then
    alter table public.host_agency_members add column shipping_agent_name text default ''; end if;
end $$;

-- ---------- 2. host_profit_levels: per-level target ----------
do $$ begin
  if not exists (select 1 from information_schema.columns where table_name='host_profit_levels' and column_name='target') then
    alter table public.host_profit_levels add column target int default 5000; end if;
  if not exists (select 1 from information_schema.columns where table_name='host_profit_levels' and column_name='period_type') then
    alter table public.host_profit_levels add column period_type text default 'weekly'; end if;
end $$;

-- Seed default profit levels if the table is empty (won't overwrite existing)
insert into public.host_profit_levels
  (level_name, min_cumulative_coins, profit_percent, target, period_type, sort_order)
select v.* from (values
  ('المستوى 1', 0,     10, 5000,  'weekly', 1),
  ('المستوى 2', 5000,  15, 10000, 'weekly', 2),
  ('المستوى 3', 15000, 20, 20000, 'weekly', 3),
  ('المستوى 4', 35000, 25, 35000, 'weekly', 4),
  ('المستوى 5', 70000, 30, 50000, 'weekly', 5)
) as v(level_name, min_cumulative_coins, profit_percent, target, period_type, sort_order)
where not exists (select 1 from public.host_profit_levels);

-- ---------- 3. agency_withdrawal_requests (with proof) ----------
do $$ begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='agency_withdrawal_requests') then
    create table public.agency_withdrawal_requests (
      id uuid primary key default gen_random_uuid(),
      agency_id text not null,
      member_user_id text not null,
      amount int not null check (amount > 0),
      status text not null default 'pending',
      note text default '',
      member_name text default '',
      member_numeric_id text default '',
      member_photo_url text default '',
      agency_name text default '',
      proof_url text default '',
      reviewed_by text,
      created_at timestamptz default now(),
      approved_at timestamptz,
      updated_at timestamptz default now()
    );
  end if;
end $$;

do $$ begin
  if not exists (select 1 from information_schema.columns where table_name='agency_withdrawal_requests' and column_name='proof_url') then
    alter table public.agency_withdrawal_requests add column proof_url text default ''; end if;
  if not exists (select 1 from information_schema.columns where table_name='agency_withdrawal_requests' and column_name='member_photo_url') then
    alter table public.agency_withdrawal_requests add column member_photo_url text default ''; end if;
end $$;

-- ---------- 4. agency_leave_requests (host -> agent approval) ----------
do $$ begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='agency_leave_requests') then
    create table public.agency_leave_requests (
      id uuid primary key default gen_random_uuid(),
      agency_id text not null,
      member_user_id text not null,
      status text not null default 'pending',
      note text default '',
      member_name text default '',
      member_numeric_id text default '',
      created_at timestamptz default now(),
      updated_at timestamptz default now()
    );
  end if;
end $$;

-- ---------- 5. agency_transfer_requests (host -> shipping agent) ----------
do $$ begin
  if not exists (select 1 from information_schema.tables where table_schema='public' and table_name='agency_transfer_requests') then
    create table public.agency_transfer_requests (
      id uuid primary key default gen_random_uuid(),
      agency_id text not null,
      from_user_id text not null,
      from_name text default '',
      from_numeric_id text default '',
      to_user_id text not null,
      to_numeric_id text not null,
      to_name text default '',
      amount int not null check (amount > 0),
      status text not null default 'pending',
      note text default '',
      proof_url text default '',
      created_at timestamptz default now(),
      approved_at timestamptz,
      updated_at timestamptz default now()
    );
  end if;
end $$;

-- ---------- 6. RLS (permissive so the app/backend/service can operate) ----------
alter table public.host_agency_members enable row level security;
alter table public.agency_withdrawal_requests enable row level security;
alter table public.agency_leave_requests enable row level security;
alter table public.agency_transfer_requests enable row level security;

do $$
declare t text;
begin
  foreach t in array array[
    'host_agency_members','agency_withdrawal_requests',
    'agency_leave_requests','agency_transfer_requests'
  ] loop
    execute format('drop policy if exists %I_sel on public.%I', t, t);
    execute format('create policy %I_sel on public.%I for select using (true)', t, t);
    execute format('drop policy if exists %I_ins on public.%I', t, t);
    execute format('create policy %I_ins on public.%I for insert with check (true)', t, t);
    execute format('drop policy if exists %I_upd on public.%I', t, t);
    execute format('create policy %I_upd on public.%I for update using (true) with check (true)', t, t);
    execute format('drop policy if exists %I_del on public.%I', t, t);
    execute format('create policy %I_del on public.%I for delete using (true)', t, t);
  end loop;
end $$;

grant select, insert, update, delete on all tables in schema public to anon, authenticated;

-- ---------- 7. Realtime ----------
do $$
declare t text;
begin
  foreach t in array array[
    'host_agency_members','agency_withdrawal_requests',
    'agency_leave_requests','agency_transfer_requests'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname='supabase_realtime' and schemaname='public' and tablename=t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- Done.
