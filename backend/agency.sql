-- ============================================================
-- Ayam Chat - AGENCY OPERATIONS SYSTEM
-- Run in: Supabase SQL Editor > New query > Run
--
-- Creates:
--   1. agency_recharges     - شحن عملات من الوكيل للمستخدم
--   2. agency_withdrawals   - سحب عملات من المستخدم للوكيل
--   3. agency_salary_runs   - جداول رواتب الأعضاء
--   4. agency_salary_items  - بنود الرواتب
--   5. RPC functions        - عمليات ذرّية (atomic) عبر السيرفر
-- ============================================================

-- ==================== 1. سجل الشحن ====================
create table if not exists public.agency_recharges (
  id uuid primary key default gen_random_uuid(),
  agency_id text not null,                        -- رقم الوكالة (4-digit)
  agent_user_id text not null,                     -- auth_uid của الوكيل
  target_user_id text not null,                    -- auth_uid của المستخدم المستهدف
  target_numeric_id text,                          -- numeric_id للمستخدم المستهدف
  diamonds int not null check (diamonds > 0),       -- عدد الماس المحمل
  cost_diamonds int not null check (cost_diamonds > 0), -- التكلفة بالعملات
  status text default 'completed'
    check (status in ('completed','reversed','failed')),
  note text,
  created_at timestamptz default now()
);

-- فهرس للبحث السريع
create index if not exists idx_recharges_agent on public.agency_recharges(agent_user_id);
create index if not exists idx_recharges_target on public.agency_recharges(target_user_id);
create index if not exists idx_recharges_agency on public.agency_recharges(agency_id);

-- ==================== 2. سجل السحب ====================
create table if not exists public.agency_withdrawals (
  id uuid primary key default gen_random_uuid(),
  agency_id text not null,
  agent_user_id text not null,                     -- الوكيل المستلم
  source_user_id text not null,                    -- المستخدم المسحوب منه
  source_numeric_id text,
  diamonds int not null check (diamonds > 0),       -- عدد الماس المسحوب
  status text default 'completed'
    check (status in ('completed','reversed','failed')),
  note text,
  created_at timestamptz default now()
);

create index if not exists idx_withdrawals_agent on public.agency_withdrawals(agent_user_id);
create index if not exists idx_withdrawals_source on public.agency_withdrawals(source_user_id);

-- ==================== 3. جدول الرواتب ====================
create table if not exists public.agency_salary_runs (
  id uuid primary key default gen_random_uuid(),
  agency_id text not null,
  agent_user_id text not null,                     -- الوكيل الذي أنشأ الجدول
  period_start timestamptz not null,               -- بداية الفترة
  period_end timestamptz not null,                 -- نهاية الفترة
  total_paid int default 0,                        -- المبلغ الكلي المدفوع
  member_count int default 0,                      -- عدد الأعضاء
  status text default 'pending'
    check (status in ('pending','paid','cancelled')),
  created_at timestamptz default now()
);

create table if not exists public.agency_salary_items (
  id uuid primary key default gen_random_uuid(),
  run_id uuid references public.agency_salary_runs(id) on delete cascade,
  user_id text not null,                           -- auth_uid العضو
  numeric_id text,                                 -- numeric_id
  username text,
  diamonds_earned int default 0,                   -- الماس المكتسب في الفترة
  salary_diamonds int default 0,                   -- الراتب بالعملات
  status text default 'pending'
    check (status in ('pending','paid','skipped')),
  created_at timestamptz default now()
);

create index if not exists idx_salary_run on public.agency_salary_items(run_id);

-- ==================== 4. أرصدة الوكالات ====================
create table if not exists public.agency_wallets (
  id uuid primary key default gen_random_uuid(),
  agency_id text unique not null,                  -- رقم الوكالة
  diamonds_balance int default 0,                  -- رصيد الماس
  total_recharged int default 0,                   -- إجمالي الشحن
  total_withdrawn int default 0,                   -- إجمالي السحب
  updated_at timestamptz default now()
);

-- ==================== 5. RPC: شحن عملات (ذري - atomic) ====================
-- يشحن الماس لمستخدم ويخصم من رصيد الوكالة في نفس المعاملة
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
security definer  -- يعمل بصلاحيات service_role
as $$
declare
  v_wallet_row record;
  v_target_row record;
  v_result jsonb;
begin
  -- 1. التحقق من رصيد الوكالة
  select * into v_wallet_row
  from public.agency_wallets
  where agency_id = p_agency_id
  for update;  -- قفل الصف

  if not found then
    return jsonb_build_object('ok', false, 'error', 'الوكالة غير موجودة');
  end if;

  if v_wallet_row.diamonds_balance < p_cost_diamonds then
    return jsonb_build_object('ok', false, 'error', 'رصيد الوكالة غير كافٍ');
  end if;

  -- 2. خصم من رصيد الوكالة
  update public.agency_wallets
  set diamonds_balance = diamonds_balance - p_cost_diamonds,
      updated_at = now()
  where agency_id = p_agency_id;

  -- 3. إضافة الماس للمستخدم
  update public.users
  set diamonds = diamonds + p_diamonds
  where auth_uid = p_target_uid;

  if not found then
    -- إرجاع الرصيد إذا المستخدم غير موجود
    update public.agency_wallets
    set diamonds_balance = diamonds_balance + p_cost_diamonds,
        updated_at = now()
    where agency_id = p_agency_id;
    return jsonb_build_object('ok', false, 'error', 'المستخدم غير موجود');
  end if;

  -- 4. تسجيل العملية
  insert into public.agency_recharges (
    agency_id, agent_user_id, target_user_id, target_numeric_id,
    diamonds, cost_diamonds, status
  ) values (
    p_agency_id, p_agent_uid, p_target_uid, p_target_numeric_id,
    p_diamonds, p_cost_diamonds, 'completed'
  );

  -- 5. تحديث الإحصائيات
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

-- ==================== 6. RPC: سحب عملات (ذري) ====================
-- يسحب الماس من مستخدم ويضيفه لرصيد الوكالة
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
  -- 1. التحقق من رصيد المستخدم
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

  -- 2. خصم من المستخدم
  update public.users
  set diamonds = diamonds - p_diamonds
  where auth_uid = p_source_uid;

  -- 3. التأكد من وجود محفظة الوكالة وإنشاؤها إذا لم تكن موجودة
  insert into public.agency_wallets (agency_id, diamonds_balance)
  values (p_agency_id, 0)
  on conflict (agency_id) do nothing;

  -- 4. إضافة لرصيد الوكالة
  update public.agency_wallets
  set diamonds_balance = diamonds_balance + p_diamonds,
      total_withdrawn = total_withdrawn + p_diamonds,
      updated_at = now()
  where agency_id = p_agency_id;

  -- 5. تسجيل العملية
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

-- ==================== 7. RPC: حساب الرواتب ====================
-- يحسب رواتب أعضاء الوكالة بناءً على الأيدي
create or replace function public.rpc_agency_calculate_salary(
  p_agency_id text,
  p_agent_uid text,
  p_user_ids text[],           -- مصفوفة auth_uid للأعضاء
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
  -- 1. إنشاء جدول الرواتب
  insert into public.agency_salary_runs (
    agency_id, agent_user_id, period_start, period_end, status
  ) values (
    p_agency_id, p_agent_uid, p_period_start, p_period_end, 'pending'
  ) returning id into v_run_id;

  -- 2. لكل عضو، نحسب الماس المكتسب في الفترة
  foreach v_user_id in array p_user_ids loop
    -- حساب مجموع الشحنات التي تلقاها هذا المستخدم في الفترة
    select coalesce(sum(diamonds), 0) into v_recharged
    from public.agency_recharges
    where target_user_id = v_user_id
      and agency_id = p_agency_id
      and created_at between p_period_start and p_period_end
      and status = 'completed';

    -- جلب بيانات المستخدم
    select numeric_id, name into v_user
    from public.users where auth_uid = v_user_id;

    -- إدراج بند الراتب
    insert into public.agency_salary_items (
      run_id, user_id, numeric_id, username,
      diamonds_earned, salary_diamonds, status
    ) values (
      v_run_id, v_user_id,
      coalesce(v_user.numeric_id, ''),
      coalesce(v_user.name, 'Unknown'),
      v_recharged,  -- الماس المكتسب
      v_recharged,  -- الراتب = الماس المكتسب (يمكن تعديله لاحقاً)
      case when v_recharged > 0 then 'pending' else 'skipped' end
    );

    if v_recharged > 0 then
      v_member_count := v_member_count + 1;
      v_total_paid := v_total_paid + v_recharged;
    end if;
  end loop;

  -- 3. تحديث الإجماليات في جدول الرواتب
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

-- ==================== 8. RPC: دفع راتب لعضو واحد ====================
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

  -- خصم من محفظة الوكالة
  update public.agency_wallets
  set diamonds_balance = diamonds_balance - v_item.salary_diamonds
  where agency_id = p_agency_id
    and diamonds_balance >= v_item.salary_diamonds;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'رصيد الوكالة غير كافٍ');
  end if;

  -- إضافة الراتب للمستخدم
  update public.users
  set diamonds = diamonds + v_item.salary_diamonds
  where auth_uid = v_item.user_id;

  -- تحديث حالة البند
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

-- ==================== 9. RLS ====================
do $$
declare t text; pol text;
begin
  foreach t in array array[
    'agency_recharges','agency_withdrawals',
    'agency_salary_runs','agency_salary_items','agency_wallets'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    -- service_role bypasses RLS, so these are permissive for anon read
    pol := t || '_select';
    execute format('drop policy if exists %I on public.%I', pol, t);
    execute format('create policy %I on public.%I for select using (true)', pol, t);
    pol := t || '_insert';
    execute format('drop policy if exists %I on public.%I', pol, t);
    execute format('create policy %I on public.%I for insert with check (true)', pol, t);
    pol := t || '_update';
    execute format('drop policy if exists %I on public.%I', pol, t);
    execute format('create policy %I on public.%I for update using (true) with check (true)', pol, t);
  end loop;
end $$;

-- Grants
grant select, insert, update on all tables in schema public to anon, authenticated;
grant execute on all functions in schema public to anon, authenticated;

-- ==================== 10. RPC: فتح وكالة لمستخدم (ذري) ====================
-- ينشئ وكالة في جدول agencies + ينشئ محفظة في agency_wallets
-- + يرسل رسالة إشعار للمستخدم
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
  -- 1. البحث عن المستخدم بالـ numeric_id
  select auth_uid, numeric_id, name into v_user
  from public.users
  where numeric_id = p_target_numeric_id;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'المستخدم غير موجود بهذا الرقم');
  end if;

  -- 2. التحقق من عدم وجود وكالة مسبقاً لهذا المستخدم
  if exists (select 1 from public.agencies where owner_id = v_user.auth_uid and is_activated = true) then
    return jsonb_build_object('ok', false, 'error', 'لديه وكالة مفعلة بالفعل');
  end if;

  -- 3. إنشاء رقم وكالة فريد
  v_agency_id := 'AG' || p_target_numeric_id;

  -- 4. إنشاء الوكالة في جدول agencies
  insert into public.agencies (
    id, name, owner_id, description, agency_type,
    is_activated, created_at, updated_at
  ) values (
    v_agency_id,
    case when p_agency_name = '' then 'وكالة ' || coalesce(v_user.name, p_target_numeric_id) else p_agency_name end,
    v_user.auth_uid,
    'وكالة ' || case when p_agency_type = 'shipping' then 'شحن' else 'موديفين' end || ' - تم الفتح بواسطة النظام',
    p_agency_type,
    true,
    now(),
    now()
  ) on conflict (id) do update set
    is_activated = true,
    updated_at = now();

  -- 5. إنشاء محفظة الوكالة
  insert into public.agency_wallets (agency_id, diamonds_balance)
  values (v_agency_id, 0)
  on conflict (agency_id) do nothing;

  -- 6. تفعيل المستخدم كوكل
  update public.users
  set is_agent = true
  where auth_uid = v_user.auth_uid;

  -- 7. إرسال رسالة إشعار للمستخدم
  -- جلب اسم الوكيل المرسل إن وُجد
  if p_agent_uid != '' then
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
    false,
    now()
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

-- ==================== 11. RLS للوكالات ====================
do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'agencies_select' and tablename = 'agencies') then
    create policy agencies_select on public.agencies for select using (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'agencies_insert' and tablename = 'agencies') then
    create policy agencies_insert on public.agencies for insert with check (true);
  end if;
  if not exists (select 1 from pg_policies where policyname = 'agencies_update' and tablename = 'agencies') then
    create policy agencies_update on public.agencies for update using (true) with check (true);
  end if;
end $$;

alter table public.agencies enable row level security;

-- Realtime للوكالات
do $$ begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'agencies'
  ) then
    execute 'alter publication supabase_realtime add table public.agencies';
  end if;
end $$;

-- ==================== 12. REALTIME ====================
do $$
declare t text;
begin
  foreach t in array array[
    'agency_recharges','agency_withdrawals',
    'agency_salary_runs','agency_salary_items','agency_wallets'
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
