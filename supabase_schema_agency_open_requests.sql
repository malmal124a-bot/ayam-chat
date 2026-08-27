-- ============================================================
-- HOST AGENCY OPEN REQUESTS (approval-gated "فتح وكالة")
-- ------------------------------------------------------------
-- A hosting user submits their own agency-open request from the
-- app (agency photo + phone + agency ID + ID card). It lands here
-- as "pending". The admin dashboard approves or rejects it; on
-- approval the agency is actually created and the owner is notified.
--
-- Idempotent: all statements guarded so it can be re-run safely.
-- ============================================================

-- 1) Table: agency_open_requests
create table if not exists public.agency_open_requests (
  id uuid primary key default gen_random_uuid(),
  requested_by text not null,          -- user auth_uid
  agency_name text not null default '',
  phone text default '',
  agency_id text not null,             -- user's numeric id (used to build 'AG{numeric}')
  photo_url text default '',           -- uploaded agency photo url
  id_card_url text default '',         -- uploaded ID card image url
  agency_type text default 'hosting',
  status text not null default 'pending', -- pending | approved | rejected
  note text default '',
  reviewed_by text,
  reviewed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Unique partial index: a user can have only ONE pending/cancelled request
create unique index if not exists uq_agency_open_requests_user_pending
  on public.agency_open_requests (requested_by)
  where status in ('pending');

-- 2) RLS: allow any authenticated user to submit & read their own requests;
--    admins use the service role key (bypasses RLS).
alter table public.agency_open_requests enable row level security;

drop policy if exists "agency_open_requests_select_own" on public.agency_open_requests;
drop policy if exists "agency_open_requests_insert" on public.agency_open_requests;
drop policy if exists "agency_open_requests_update_own" on public.agency_open_requests;

create policy "agency_open_requests_select_own"
  on public.agency_open_requests for select
  using (auth.uid()::text = requested_by);

create policy "agency_open_requests_insert"
  on public.agency_open_requests for insert
  with check (auth.uid()::text = requested_by);

create policy "agency_open_requests_update_own"
  on public.agency_open_requests for update
  using (auth.uid()::text = requested_by);

-- 3) Broadcast over realtime so the app can react instantly to status changes.
do $$
declare
  t text := 'agency_open_requests';
begin
  if to_regclass('public.' || t) is not null
     and not exists (
        select 1 from pg_publication_tables
        where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
     ) then
    execute format('alter publication supabase_realtime add table public.%I', t);
  end if;
end $$;
