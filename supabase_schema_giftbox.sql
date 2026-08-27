-- ====================================================================
-- PATCH: إعداد جدول إعدادات التطبيق (app_config) لربط صندوق الهدايا بلوحة التحكم
-- الصق هذا الكود في Supabase Dashboard > SQL Editor > Run
-- آمن لإعادة التشغيل (if not exists)
-- ملاحظة: إن كان جدول app_config موجوداً أصلاً (تم إنشاؤه من اللوحة)،
-- لن يغيّر هذا الكود بنيته — فقط يضيف السياسات للقراءة من التطبيق.
-- ====================================================================

create table if not exists public.app_config (
  key text primary key,
  value text,
  updated_at timestamptz default now()
);

-- ==================== ROW LEVEL SECURITY ====================
alter table public.app_config enable row level security;

drop policy if exists "app_config_select" on public.app_config;
drop policy if exists "app_config_insert" on public.app_config;
drop policy if exists "app_config_update" on public.app_config;
drop policy if exists "app_config_delete" on public.app_config;
create policy "app_config_select" on public.app_config for select using (true);
create policy "app_config_insert" on public.app_config for insert with check (true);
create policy "app_config_update" on public.app_config for update using (true) with check (true);
create policy "app_config_delete" on public.app_config for delete using (true);

-- ==================== REALTIME ====================
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'app_config'
  ) then
    alter publication supabase_realtime add table public.app_config;
  end if;
end $$;
