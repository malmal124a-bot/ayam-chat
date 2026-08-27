-- ============================================================
-- FIX: host_agency_members + host_agency_join_requests
-- agency_id must be TEXT (not UUID) to match agencies.id = 'AG271555'
-- Run in Supabase SQL Editor
-- ============================================================

-- 1. Fix host_agency_members
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'host_agency_members' AND column_name = 'agency_id' AND udt_name = 'uuid'
  ) THEN
    ALTER TABLE public.host_agency_members DROP CONSTRAINT IF EXISTS host_agency_members_agency_id_fkey;
    ALTER TABLE public.host_agency_members ALTER COLUMN agency_id TYPE text USING agency_id::text;
  END IF;
END $$;

-- Also fix user_id if it's UUID (should be text = auth_uid)
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'host_agency_members' AND column_name = 'user_id' AND udt_name = 'uuid'
  ) THEN
    ALTER TABLE public.host_agency_members DROP CONSTRAINT IF EXISTS host_agency_members_user_id_fkey;
    ALTER TABLE public.host_agency_members ALTER COLUMN user_id TYPE text USING user_id::text;
  END IF;
END $$;

-- 2. Fix host_agency_join_requests
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'host_agency_join_requests' AND column_name = 'agency_id' AND udt_name = 'uuid'
  ) THEN
    ALTER TABLE public.host_agency_join_requests DROP CONSTRAINT IF EXISTS host_agency_join_requests_agency_id_fkey;
    ALTER TABLE public.host_agency_join_requests ALTER COLUMN agency_id TYPE text USING agency_id::text;
  END IF;
END $$;

-- Also fix user_id if it's UUID
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'host_agency_join_requests' AND column_name = 'user_id' AND udt_name = 'uuid'
  ) THEN
    ALTER TABLE public.host_agency_join_requests DROP CONSTRAINT IF EXISTS host_agency_join_requests_user_id_fkey;
    ALTER TABLE public.host_agency_join_requests ALTER COLUMN user_id TYPE text USING user_id::text;
  END IF;
END $$;

-- 3. Ensure RLS is set
ALTER TABLE public.host_agency_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.host_agency_join_requests ENABLE ROW LEVEL SECURITY;

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

-- 4. Also add photo_url column to agencies if missing
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'agencies' AND column_name = 'photo_url'
  ) THEN
    ALTER TABLE public.agencies ADD COLUMN photo_url text default '';
  END IF;
END $$;

-- 5. Also add agency_type column to agencies if missing
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'agencies' AND column_name = 'agency_type'
  ) THEN
    ALTER TABLE public.agencies ADD COLUMN agency_type text default 'mixed';
  END IF;
END $$;

-- Grants
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
