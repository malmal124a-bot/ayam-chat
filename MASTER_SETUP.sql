-- ============================================================
-- Ayam Chat - MASTER DATABASE SETUP
-- هذا الملف يحتوي على كل شي — شغّله مرة وحدة في Supabase SQL Editor
-- ============================================================

-- ============================================================
-- PART 1: AGENCY OPERATIONS (agency.sql)
-- ============================================================

-- 1. سجل الشحن
create table if not exists public.agency_recharges (
  id uuid primary key default gen_random_uuid(),
  agency_id text not null,
  agent_user_id text not null,
  target_user_id text not null,
  target_numeric_id text,
  diamonds int not null check (diamonds > 0),
  cost_diamonds int not null check (cost_diamonds > 0),
  status text default 'completed'
    check (status in ('completed','reversed','failed')),
  note text,
  created_at timestamptz default now()
);
create index if not exists idx_recharges_agent on public.agency_recharges(agent_user_id);
create index if not exists idx_recharges_target on public.agency_recharges(target_user_id);
create index if not exists idx_recharges_agency on public.agency_recharges(agency_id);

-- 2. سجل السحب
create table if not exists public.agency_withdrawals (
  id uuid primary key default gen_random_uuid(),
  agency_id text not null,
  agent_user_id text not null,
  source_user_id text not null,
  source_numeric_id text,
  diamonds int not null check (diamonds > 0),
  status text default 'completed'
    check (status in ('completed','reversed','failed')),
  note text,
  created_at timestamptz default now()
);
create index if not exists idx_withdrawals_agent on public.agency_withdrawals(agent_user_id);
create index if not exists idx_withdrawals_source on public.agency_withdrawals(source_user_id);

-- 3. جدول الرواتب
create table if not exists public.agency_salary_runs (
  id uuid primary key default gen_random_uuid(),
  agency_id text not null,
  agent_user_id text not null,
  period_start timestamptz not null,
  period_end timestamptz not null,
  total_paid int default 0,
  member_count int default 0,
  status text default 'pending'
    check (status in ('pending','paid','cancelled')),
  created_at timestamptz default now()
);

create table if not exists public.agency_salary_items (
  id uuid primary key default gen_random_uuid(),
  run_id uuid references public.agency_salary_runs(id) on delete cascade,
  user_id text not null,
  numeric_id text,
  username text,
  diamonds_earned int default 0,
  salary_diamonds int default 0,
  status text default 'pending'
    check (status in ('pending','paid','skipped')),
  created_at timestamptz default now()
);
create index if not exists idx_salary_run on public.agency_salary_items(run_id);

-- 4. أرصدة الوكالات
create table if not exists public.agency_wallets (
  id uuid primary key default gen_random_uuid(),
  agency_id text unique not null,
  diamonds_balance int default 0,
  total_recharged int default 0,
  total_withdrawn int default 0,
  updated_at timestamptz default now()
);

-- 5. RPC: شحن عملات
create or replace function public.rpc_agency_recharge(
  p_agency_id text,
  p_agent_uid text,
  p_target_uid text,
  p_target_numeric_id text,
  p_diamonds int,
  p_cost_diamonds int
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_wallet_row record;
  v_target_row record;
begin
  select * into v_wallet_row
  from public.agency_wallets
  where agency_id = p_agency_id
  for update;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'الوكالة غير موجودة');
  end if;

  if v_wallet_row.diamonds_balance < p_cost_diamonds then
    return jsonb_build_object('ok', false, 'error', 'رصيد الوكالة غير كافٍ');
  end if;

  update public.agency_wallets
  set diamonds_balance = diamonds_balance - p_cost_diamonds, updated_at = now()
  where agency_id = p_agency_id;

  update public.users
  set diamonds = diamonds + p_diamonds
  where auth_uid = p_target_uid;

  if not found then
    update public.agency_wallets
    set diamonds_balance = diamonds_balance + p_cost_diamonds, updated_at = now()
    where agency_id = p_agency_id;
    return jsonb_build_object('ok', false, 'error', 'المستخدم غير موجود');
  end if;

  insert into public.agency_recharges (
    agency_id, agent_user_id, target_user_id, target_numeric_id,
    diamonds, cost_diamonds, status
  ) values (
    p_agency_id, p_agent_uid, p_target_uid, p_target_numeric_id,
    p_diamonds, p_cost_diamonds, 'completed'
  );

  update public.agency_wallets
  set total_recharged = total_recharged + p_diamonds
  where agency_id = p_agency_id;

  return jsonb_build_object(
    'ok', true,
    'diamonds_charged', p_diamonds,
    'cost_diamonds', p_cost_diamonds,
    'remaining_balance', v_wallet_row.diamonds_balance - p_cost_diamonds
  );
end;
$$;

-- 6. RPC: سحب عملات
create or replace function public.rpc_agency_withdraw(
  p_agency_id text,
  p_agent_uid text,
  p_source_uid text,
  p_source_numeric_id text,
  p_diamonds int
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_source_row record;
  v_wallet_row record;
begin
  select diamonds into v_source_row
  from public.users
  where auth_uid = p_source_uid
  for update;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'المستخدم غير موجود');
  end if;

  if v_source_row.diamonds < p_diamonds then
    return jsonb_build_object('ok', false, 'error', 'رصيد المستخدم غير كافٍ');
  end if;

  update public.users
  set diamonds = diamonds - p_diamonds
  where auth_uid = p_source_uid;

  insert into public.agency_wallets (agency_id, diamonds_balance)
  values (p_agency_id, 0)
  on conflict (agency_id) do nothing;

  update public.agency_wallets
  set diamonds_balance = diamonds_balance + p_diamonds,
      total_withdrawn = total_withdrawn + p_diamonds,
      updated_at = now()
  where agency_id = p_agency_id;

  insert into public.agency_withdrawals (
    agency_id, agent_user_id, source_user_id, source_numeric_id,
    diamonds, status
  ) values (
    p_agency_id, p_agent_uid, p_source_uid, p_source_numeric_id,
    p_diamonds, 'completed'
  );

  return jsonb_build_object(
    'ok', true,
    'diamonds_withdrawn', p_diamonds,
    'new_balance', v_source_row.diamonds - p_diamonds
  );
end;
$$;

-- 7. RPC: حساب الرواتب
create or replace function public.rpc_agency_calculate_salary(
  p_agency_id text,
  p_agent_uid text,
  p_user_ids text[],
  p_period_start timestamptz,
  p_period_end timestamptz
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_run_id uuid;
  v_user_id text;
  v_user record;
  v_recharged int;
  v_member_count int := 0;
  v_total_paid int := 0;
begin
  insert into public.agency_salary_runs (
    agency_id, agent_user_id, period_start, period_end, status
  ) values (
    p_agency_id, p_agent_uid, p_period_start, p_period_end, 'pending'
  ) returning id into v_run_id;

  foreach v_user_id in array p_user_ids loop
    select coalesce(sum(diamonds), 0) into v_recharged
    from public.agency_recharges
    where target_user_id = v_user_id
      and agency_id = p_agency_id
      and created_at between p_period_start and p_period_end
      and status = 'completed';

    select numeric_id, name into v_user
    from public.users where auth_uid = v_user_id;

    insert into public.agency_salary_items (
      run_id, user_id, numeric_id, username,
      diamonds_earned, salary_diamonds, status
    ) values (
      v_run_id, v_user_id,
      coalesce(v_user.numeric_id, ''),
      coalesce(v_user.name, 'Unknown'),
      v_recharged,
      v_recharged,
      case when v_recharged > 0 then 'pending' else 'skipped' end
    );

    if v_recharged > 0 then
      v_member_count := v_member_count + 1;
      v_total_paid := v_total_paid + v_recharged;
    end if;
  end loop;

  update public.agency_salary_runs
  set total_paid = v_total_paid, member_count = v_member_count
  where id = v_run_id;

  return jsonb_build_object(
    'ok', true,
    'run_id', v_run_id,
    'member_count', v_member_count,
    'total_paid', v_total_paid
  );
end;
$$;

-- 8. RPC: دفع راتب لعضو واحد
create or replace function public.rpc_agency_pay_salary_item(
  p_item_id uuid,
  p_agency_id text
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_item record;
begin
  select * into v_item
  from public.agency_salary_items
  where id = p_item_id and status = 'pending'
  for update;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'بند الراتب غير موجود أو مدفوع بالفعل');
  end if;

  update public.agency_wallets
  set diamonds_balance = diamonds_balance - v_item.salary_diamonds
  where agency_id = p_agency_id
    and diamonds_balance >= v_item.salary_diamonds;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'رصيد الوكالة غير كافٍ');
  end if;

  update public.users
  set diamonds = diamonds + v_item.salary_diamonds
  where auth_uid = v_item.user_id;

  update public.agency_salary_items
  set status = 'paid'
  where id = p_item_id;

  return jsonb_build_object(
    'ok', true,
    'user_id', v_item.user_id,
    'salary_diamonds', v_item.salary_diamonds
  );
end;
$$;

-- 9. RPC: فتح وكالة لمستخدم
create or replace function public.rpc_open_agency_for_user(
  p_target_numeric_id text,
  p_agency_name text default '',
  p_agency_type text default 'shipping',
  p_agent_uid text default ''
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_user record;
  v_agency_id text;
  v_sender_name text;
begin
  select auth_uid, numeric_id, name into v_user
  from public.users
  where numeric_id = p_target_numeric_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'المستخدم غير موجود بهذا الرقم');
  end if;

  if exists (select 1 from public.agencies where owner_id = v_user.auth_uid and is_activated = true) then
    return jsonb_build_object('ok', false, 'error', 'لديه وكالة مفعلة بالفعل');
  end if;

  v_agency_id := 'AG' || p_target_numeric_id;

  insert into public.agencies (
    id, name, owner_id, description, agency_type,
    is_activated, created_at, updated_at
  ) values (
    v_agency_id,
    case when p_agency_name = '' then 'وكالة ' || coalesce(v_user.name, p_target_numeric_id) else p_agency_name end,
    v_user.auth_uid,
    'وكالة ' || case when p_agency_type = 'shipping' then 'شحن' else 'موديفين' end || ' - تم الفتح بواسطة النظام',
    p_agency_type,
    true, now(), now()
  ) on conflict (id) do update set
    is_activated = true, updated_at = now();

  insert into public.agency_wallets (agency_id, diamonds_balance)
  values (v_agency_id, 0)
  on conflict (agency_id) do nothing;

  update public.users
  set is_agent = true
  where auth_uid = v_user.auth_uid;

  if p_agent_uid != '' and p_agent_uid is not null then
    select name into v_sender_name from public.users where auth_uid = p_agent_uid;
  end if;

  insert into public.dm_messages (
    from_user_id, to_user_id, from_name, to_name,
    text, is_read, created_at
  ) values (
    case when p_agent_uid = '' or p_agent_uid is null then 'system' else p_agent_uid end,
    p_target_numeric_id,
    coalesce(v_sender_name, 'النظام'),
    coalesce(v_user.name, p_target_numeric_id),
    'تم فتح وكالة جديدة لك! رقم الوكالة: ' || v_agency_id || '. يمكنك الآن الدخول إلى شاشة الوكالة من البروفايل.',
    false, now()
  );

  return jsonb_build_object(
    'ok', true,
    'agency_id', v_agency_id,
    'user_name', coalesce(v_user.name, ''),
    'user_numeric_id', p_target_numeric_id,
    'message', 'تم فتح الوكالة وإرسال إشعار للمستخدم'
  );
end;
$$;


-- ============================================================
-- PART 2: AGENCY PAYMENTS (agency_payments.sql)
-- ============================================================

-- 1. بوابات الدفع
CREATE TABLE IF NOT EXISTS payment_gateways (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('vodafone_cash','etisalat_cash','syriatel_cash','usdt_trc20','bank_transfer')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  account_number TEXT,
  account_name TEXT,
  bank_name TEXT,
  wallet_address TEXT,
  instructions TEXT,
  instructions_ar TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. طلبات الشحن
CREATE TABLE IF NOT EXISTS agency_topup_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id TEXT NOT NULL REFERENCES agencies(id),
  owner_uid TEXT NOT NULL,
  gateway_id TEXT NOT NULL REFERENCES payment_gateways(id),
  amount_usd NUMERIC NOT NULL CHECK (amount_usd > 0),
  diamonds NUMERIC NOT NULL CHECK (diamonds > 0),
  payment_proof_url TEXT,
  sender_number TEXT,
  transaction_ref TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  admin_note TEXT,
  reviewed_by TEXT,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. سجل الشحنات
CREATE TABLE IF NOT EXISTS agency_topup_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID REFERENCES agency_topup_requests(id),
  agency_id TEXT NOT NULL,
  gateway_id TEXT,
  amount_usd NUMERIC NOT NULL,
  diamonds NUMERIC NOT NULL,
  approved_by TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RPC: قبول طلب شحن
CREATE OR REPLACE FUNCTION rpc_approve_topup(
  p_request_id UUID,
  p_admin_id TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_req RECORD;
  v_new_balance NUMERIC;
BEGIN
  SELECT * INTO v_req FROM agency_topup_requests WHERE id = p_request_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'طلب غير موجود');
  END IF;
  IF v_req.status != 'pending' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'تم معالجة هذا الطلب مسبقاً');
  END IF;

  INSERT INTO agency_wallets (agency_id, diamonds_balance, total_recharged)
  VALUES (v_req.agency_id, 0, 0)
  ON CONFLICT (agency_id) DO NOTHING;

  UPDATE agency_wallets
  SET diamonds_balance = diamonds_balance + v_req.diamonds,
      total_recharged = total_recharged + v_req.diamonds
  WHERE agency_id = v_req.agency_id
  RETURNING diamonds_balance INTO v_new_balance;

  UPDATE agency_topup_requests
  SET status = 'approved', reviewed_by = p_admin_id, reviewed_at = now()
  WHERE id = p_request_id;

  INSERT INTO agency_topup_logs (request_id, agency_id, gateway_id, amount_usd, diamonds, approved_by)
  VALUES (p_request_id, v_req.agency_id, v_req.gateway_id, v_req.amount_usd, v_req.diamonds, p_admin_id);

  RETURN jsonb_build_object('ok', true, 'new_balance', v_new_balance, 'diamonds_added', v_req.diamonds);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: رفض طلب شحن
CREATE OR REPLACE FUNCTION rpc_reject_topup(
  p_request_id UUID,
  p_admin_id TEXT,
  p_reason TEXT DEFAULT ''
)
RETURNS JSONB AS $$
BEGIN
  UPDATE agency_topup_requests
  SET status = 'rejected', admin_note = p_reason, reviewed_by = p_admin_id, reviewed_at = now()
  WHERE id = p_request_id AND status = 'pending';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'طلب غير موجود أو تم معالجته');
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: شحن مباشر من الأدمن
CREATE OR REPLACE FUNCTION rpc_admin_topup_agency(
  p_agency_id TEXT,
  p_diamonds NUMERIC,
  p_admin_id TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_new_balance NUMERIC;
BEGIN
  IF p_diamonds <= 0 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'يجب أن يكون المبلغ أكبر من صفر');
  END IF;

  INSERT INTO agency_wallets (agency_id, diamonds_balance, total_recharged)
  VALUES (p_agency_id, 0, 0)
  ON CONFLICT (agency_id) DO NOTHING;

  UPDATE agency_wallets
  SET diamonds_balance = diamonds_balance + p_diamonds,
      total_recharged = total_recharged + p_diamonds
  WHERE agency_id = p_agency_id
  RETURNING diamonds_balance INTO v_new_balance;

  INSERT INTO agency_topup_logs (agency_id, amount_usd, diamonds, approved_by)
  VALUES (p_agency_id, 0, p_diamonds, p_admin_id);

  RETURN jsonb_build_object('ok', true, 'new_balance', v_new_balance, 'diamonds_added', p_diamonds);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- بوابات الدفع الافتراضية
INSERT INTO payment_gateways (id, name, name_ar, type, is_active, sort_order) VALUES
  ('gw_vodafone', 'Vodafone Cash', 'فودافون كاش', 'vodafone_cash', true, 1),
  ('gw_etisalat', 'Etisalat Cash', 'اتصالات كاش', 'etisalat_cash', true, 2),
  ('gw_syriatel', 'Syriatel Cash', 'سيرياتيل كاش', 'syriatel_cash', true, 3),
  ('gw_usdt', 'USDT (TRC20)', 'يوي إس دي تي', 'usdt_trc20', true, 4),
  ('gw_bank', 'Bank Transfer', 'تحويل بنكي', 'bank_transfer', true, 5)
ON CONFLICT (id) DO NOTHING;


-- ============================================================
-- PART 3: FIX COLUMNS (fix_agency_tables.sql)
-- ============================================================

-- Fix agencies: أضف photo_url و agency_type إذا مو موجودة
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'agencies' AND column_name = 'photo_url') THEN
    ALTER TABLE public.agencies ADD COLUMN photo_url text default '';
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'agencies' AND column_name = 'agency_type') THEN
    ALTER TABLE public.agencies ADD COLUMN agency_type text default 'mixed';
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'agencies' AND column_name = 'commission_rate') THEN
    ALTER TABLE public.agencies ADD COLUMN commission_rate double precision default 0.05;
  END IF;
END $$;

-- Fix host_agency_members: agency_id و user_id يجب أن يكون TEXT
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'host_agency_members' AND column_name = 'agency_id' AND udt_name = 'uuid') THEN
    ALTER TABLE public.host_agency_members DROP CONSTRAINT IF EXISTS host_agency_members_agency_id_fkey;
    ALTER TABLE public.host_agency_members ALTER COLUMN agency_id TYPE text USING agency_id::text;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'host_agency_members' AND column_name = 'user_id' AND udt_name = 'uuid') THEN
    ALTER TABLE public.host_agency_members DROP CONSTRAINT IF EXISTS host_agency_members_user_id_fkey;
    ALTER TABLE public.host_agency_members ALTER COLUMN user_id TYPE text USING user_id::text;
  END IF;
END $$;

-- Fix host_agency_join_requests
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'host_agency_join_requests' AND column_name = 'agency_id' AND udt_name = 'uuid') THEN
    ALTER TABLE public.host_agency_join_requests DROP CONSTRAINT IF EXISTS host_agency_join_requests_agency_id_fkey;
    ALTER TABLE public.host_agency_join_requests ALTER COLUMN agency_id TYPE text USING agency_id::text;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'host_agency_join_requests' AND column_name = 'user_id' AND udt_name = 'uuid') THEN
    ALTER TABLE public.host_agency_join_requests DROP CONSTRAINT IF EXISTS host_agency_join_requests_user_id_fkey;
    ALTER TABLE public.host_agency_join_requests ALTER COLUMN user_id TYPE text USING user_id::text;
  END IF;
END $$;


-- ============================================================
-- PART 4: RLS POLICIES (للكل الجداول)
-- ============================================================

-- RLS: agency tables
ALTER TABLE public.agencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.host_agency_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.host_agency_join_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agency_recharges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agency_withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agency_salary_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agency_salary_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agency_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_gateways ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agency_topup_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agency_topup_logs ENABLE ROW LEVEL SECURITY;

-- agencies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agencies_select' AND tablename = 'agencies') THEN
    CREATE POLICY agencies_select ON public.agencies FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agencies_insert' AND tablename = 'agencies') THEN
    CREATE POLICY agencies_insert ON public.agencies FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agencies_update' AND tablename = 'agencies') THEN
    CREATE POLICY agencies_update ON public.agencies FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

-- host_agency_members
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'ham_select' AND tablename = 'host_agency_members') THEN
    CREATE POLICY ham_select ON public.host_agency_members FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'ham_insert' AND tablename = 'host_agency_members') THEN
    CREATE POLICY ham_insert ON public.host_agency_members FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'ham_update' AND tablename = 'host_agency_members') THEN
    CREATE POLICY ham_update ON public.host_agency_members FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'ham_delete' AND tablename = 'host_agency_members') THEN
    CREATE POLICY ham_delete ON public.host_agency_members FOR DELETE USING (true);
  END IF;
END $$;

-- host_agency_join_requests
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'hajr_select' AND tablename = 'host_agency_join_requests') THEN
    CREATE POLICY hajr_select ON public.host_agency_join_requests FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'hajr_insert' AND tablename = 'host_agency_join_requests') THEN
    CREATE POLICY hajr_insert ON public.host_agency_join_requests FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'hajr_update' AND tablename = 'host_agency_join_requests') THEN
    CREATE POLICY hajr_update ON public.host_agency_join_requests FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'hajr_delete' AND tablename = 'host_agency_join_requests') THEN
    CREATE POLICY hajr_delete ON public.host_agency_join_requests FOR DELETE USING (true);
  END IF;
END $$;

-- agency_recharges
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_recharges_select' AND tablename = 'agency_recharges') THEN
    CREATE POLICY agency_recharges_select ON public.agency_recharges FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_recharges_insert' AND tablename = 'agency_recharges') THEN
    CREATE POLICY agency_recharges_insert ON public.agency_recharges FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_recharges_update' AND tablename = 'agency_recharges') THEN
    CREATE POLICY agency_recharges_update ON public.agency_recharges FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

-- agency_withdrawals
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_withdrawals_select' AND tablename = 'agency_withdrawals') THEN
    CREATE POLICY agency_withdrawals_select ON public.agency_withdrawals FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_withdrawals_insert' AND tablename = 'agency_withdrawals') THEN
    CREATE POLICY agency_withdrawals_insert ON public.agency_withdrawals FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_withdrawals_update' AND tablename = 'agency_withdrawals') THEN
    CREATE POLICY agency_withdrawals_update ON public.agency_withdrawals FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

-- agency_salary_runs
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_salary_runs_select' AND tablename = 'agency_salary_runs') THEN
    CREATE POLICY agency_salary_runs_select ON public.agency_salary_runs FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_salary_runs_insert' AND tablename = 'agency_salary_runs') THEN
    CREATE POLICY agency_salary_runs_insert ON public.agency_salary_runs FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_salary_runs_update' AND tablename = 'agency_salary_runs') THEN
    CREATE POLICY agency_salary_runs_update ON public.agency_salary_runs FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

-- agency_salary_items
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_salary_items_select' AND tablename = 'agency_salary_items') THEN
    CREATE POLICY agency_salary_items_select ON public.agency_salary_items FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_salary_items_insert' AND tablename = 'agency_salary_items') THEN
    CREATE POLICY agency_salary_items_insert ON public.agency_salary_items FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_salary_items_update' AND tablename = 'agency_salary_items') THEN
    CREATE POLICY agency_salary_items_update ON public.agency_salary_items FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

-- agency_wallets
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_wallets_select' AND tablename = 'agency_wallets') THEN
    CREATE POLICY agency_wallets_select ON public.agency_wallets FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_wallets_insert' AND tablename = 'agency_wallets') THEN
    CREATE POLICY agency_wallets_insert ON public.agency_wallets FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'agency_wallets_update' AND tablename = 'agency_wallets') THEN
    CREATE POLICY agency_wallets_update ON public.agency_wallets FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

-- payment_gateways, topup_requests, topup_logs
DROP POLICY IF EXISTS "pg_read" ON payment_gateways;
CREATE POLICY "pg_read" ON payment_gateways FOR SELECT USING (true);

DROP POLICY IF EXISTS "atr_read" ON agency_topup_requests;
CREATE POLICY "atr_read" ON agency_topup_requests FOR SELECT USING (true);
DROP POLICY IF EXISTS "atr_insert" ON agency_topup_requests;
CREATE POLICY "atr_insert" ON agency_topup_requests FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "atr_update" ON agency_topup_requests;
CREATE POLICY "atr_update" ON agency_topup_requests FOR UPDATE USING (true);

DROP POLICY IF EXISTS "atl_read" ON agency_topup_logs;
CREATE POLICY "atl_read" ON agency_topup_logs FOR SELECT USING (true);
DROP POLICY IF EXISTS "atl_insert" ON agency_topup_logs;
CREATE POLICY "atl_insert" ON agency_topup_logs FOR INSERT WITH CHECK (true);


-- ============================================================
-- PART 5: GRANTS + REALTIME
-- ============================================================

-- Grants
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant execute on all functions in schema public to anon, authenticated;

-- Realtime: agencies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'agencies'
  ) THEN
    EXECUTE 'alter publication supabase_realtime add table public.agencies';
  END IF;
END $$;

-- Realtime: agency tables
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'agency_recharges') THEN
    EXECUTE 'alter publication supabase_realtime add table public.agency_recharges';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'agency_withdrawals') THEN
    EXECUTE 'alter publication supabase_realtime add table public.agency_withdrawals';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'agency_salary_runs') THEN
    EXECUTE 'alter publication supabase_realtime add table public.agency_salary_runs';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'agency_salary_items') THEN
    EXECUTE 'alter publication supabase_realtime add table public.agency_salary_items';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'agency_wallets') THEN
    EXECUTE 'alter publication supabase_realtime add table public.agency_wallets';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'host_agency_members') THEN
    EXECUTE 'alter publication supabase_realtime add table public.host_agency_members';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'host_agency_join_requests') THEN
    EXECUTE 'alter publication supabase_realtime add table public.host_agency_join_requests';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'payment_gateways') THEN
    EXECUTE 'alter publication supabase_realtime add table public.payment_gateways';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'agency_topup_requests') THEN
    EXECUTE 'alter publication supabase_realtime add table public.agency_topup_requests';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'agency_topup_logs') THEN
    EXECUTE 'alter publication supabase_realtime add table public.agency_topup_logs';
  END IF;
END $$;

-- ============================================================
-- ROOM MODERATION: Bans & Moderators
-- ============================================================

-- Add moderators column to rooms table (JSON array of user numeric IDs)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'rooms' AND column_name = 'moderators') THEN
    ALTER TABLE rooms ADD COLUMN moderators JSONB DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- Room bans table
CREATE TABLE IF NOT EXISTS room_bans (
  id BIGSERIAL PRIMARY KEY,
  room_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  user_name TEXT,
  banned_at TIMESTAMPTZ DEFAULT now(),
  banned_by TEXT,
  UNIQUE(room_id, user_id)
);

-- Enable RLS on room_bans
ALTER TABLE room_bans ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on room_bans' AND tablename = 'room_bans') THEN
    CREATE POLICY "Allow all on room_bans" ON room_bans FOR ALL USING (true);
  END IF;
END $$;

-- Enable realtime for room_bans
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'room_bans') THEN
    EXECUTE 'alter publication supabase_realtime add table public.room_bans';
  END IF;
END $$;

-- ============================================================
-- FAMILY SYSTEM
-- ============================================================

-- Families table
CREATE TABLE IF NOT EXISTS families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  rules TEXT DEFAULT '',
  image_url TEXT DEFAULT '',
  owner_uid TEXT NOT NULL,
  owner_name TEXT NOT NULL,
  diamonds INT DEFAULT 0,
  level INT DEFAULT 1,
  member_count INT DEFAULT 1,
  create_cost INT DEFAULT 5000,
  min_level_to_create INT DEFAULT 5,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_families_owner ON families(owner_uid);
CREATE INDEX IF NOT EXISTS idx_families_code ON families(family_code);

-- Family members table
CREATE TABLE IF NOT EXISTS family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  user_uid TEXT NOT NULL,
  user_numeric_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  user_avatar TEXT DEFAULT '',
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  contribution INT DEFAULT 0,
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(family_id, user_uid)
);

CREATE INDEX IF NOT EXISTS idx_family_members_family ON family_members(family_id);
CREATE INDEX IF NOT EXISTS idx_family_members_user ON family_members(user_uid);

-- Family invites table
CREATE TABLE IF NOT EXISTS family_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  family_name TEXT NOT NULL,
  sender_uid TEXT NOT NULL,
  sender_name TEXT NOT NULL,
  target_uid TEXT NOT NULL,
  target_name TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_family_invites_target ON family_invites(target_uid);
CREATE INDEX IF NOT EXISTS idx_family_invites_family ON family_invites(family_id);

-- Enable RLS
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_invites ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on families' AND tablename = 'families') THEN
    CREATE POLICY "Allow all on families" ON families FOR ALL USING (true);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on family_members' AND tablename = 'family_members') THEN
    CREATE POLICY "Allow all on family_members" ON family_members FOR ALL USING (true);
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on family_invites' AND tablename = 'family_invites') THEN
    CREATE POLICY "Allow all on family_invites" ON family_invites FOR ALL USING (true);
  END IF;
END $$;

-- Enable realtime
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'families') THEN
    EXECUTE 'alter publication supabase_realtime add table public.families';
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'family_members') THEN
    EXECUTE 'alter publication supabase_realtime add table public.family_members';
  END IF;
END $$;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'family_invites') THEN
    EXECUTE 'alter publication supabase_realtime add table public.family_invites';
  END IF;
END $$;

-- Add country column to users table
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'country') THEN
    ALTER TABLE users ADD COLUMN country TEXT DEFAULT '';
  END IF;
END $$;

-- ============================================================
-- PART: AGENCY COMMISSION SETTINGS
-- ============================================================

CREATE TABLE IF NOT EXISTS agency_commission_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id TEXT NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  commission_percent NUMERIC DEFAULT 100,
  gift_entry_percent NUMERIC DEFAULT 100,
  host_profit_percent NUMERIC DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(agency_id)
);

ALTER TABLE agency_commission_settings ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on agency_commission_settings' AND tablename = 'agency_commission_settings') THEN
    CREATE POLICY "Allow all on agency_commission_settings" ON agency_commission_settings FOR ALL USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'agency_commission_settings') THEN
    EXECUTE 'alter publication supabase_realtime add table public.agency_commission_settings';
  END IF;
END $$;

-- Global commission settings keys for gift system
INSERT INTO commission_settings (id, key, value) VALUES
  (gen_random_uuid(), 'gift_commission_percent', 100),
  (gen_random_uuid(), 'gift_entry_percent', 100),
  (gen_random_uuid(), 'host_profit_percent', 100)
ON CONFLICT (key) DO NOTHING;

-- Host profit levels
CREATE TABLE IF NOT EXISTS host_profit_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level_name TEXT NOT NULL,
  min_cumulative_coins BIGINT DEFAULT 0,
  profit_percent NUMERIC DEFAULT 50,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE host_profit_levels ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on host_profit_levels' AND tablename = 'host_profit_levels') THEN
    CREATE POLICY "Allow all on host_profit_levels" ON host_profit_levels FOR ALL USING (true);
  END IF;
END $$;

INSERT INTO host_profit_levels (level_name, min_cumulative_coins, profit_percent, sort_order) VALUES
  ('المستوى 1', 1000000, 40, 1),
  ('المستوى 2', 5000000, 50, 2),
  ('المستوى 3', 10000000, 60, 3),
  ('المستوى 4', 50000000, 70, 4),
  ('المستوى 5', 100000000, 80, 5)
ON CONFLICT DO NOTHING;

-- ============================================================
-- PART: SENT GIFTS TRACKING TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS sent_gifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gift_id TEXT NOT NULL DEFAULT '',
  gift_name TEXT NOT NULL DEFAULT '',
  gift_image_url TEXT DEFAULT '',
  sender_id TEXT NOT NULL DEFAULT '',
  sender_name TEXT NOT NULL DEFAULT '',
  sender_photo_url TEXT DEFAULT '',
  receiver_id TEXT NOT NULL DEFAULT '',
  room_id TEXT DEFAULT '',
  value NUMERIC DEFAULT 0,
  count INT DEFAULT 1,
  timestamp BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE sent_gifts ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all on sent_gifts' AND tablename = 'sent_gifts') THEN
    CREATE POLICY "Allow all on sent_gifts" ON sent_gifts FOR ALL USING (true);
  END IF;
END $$;
