-- Run this script in your Supabase SQL Editor to fix the PGRST703 error
-- It creates the missing tables for agency open requests and top-up requests,
-- sets up row level security (RLS), and grants access to PostgREST.

-- 1. Create agency_open_requests table
CREATE TABLE IF NOT EXISTS public.agency_open_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requested_by text NOT NULL,
  agency_name text NOT NULL,
  phone text DEFAULT '',
  agency_id text DEFAULT '',
  photo_url text DEFAULT '',
  id_card_url text DEFAULT '',
  agency_type text DEFAULT 'hosting',
  status text NOT NULL DEFAULT 'pending',
  note text DEFAULT '',
  reviewed_by text,
  reviewed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_agency_open_requests_user_pending
  ON public.agency_open_requests (requested_by) WHERE status = 'pending';

-- 2. Create payment gateways and top-up tables
CREATE TABLE IF NOT EXISTS public.payment_gateways (
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

CREATE TABLE IF NOT EXISTS public.agency_topup_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id TEXT NOT NULL REFERENCES public.agencies(id),
  owner_uid TEXT NOT NULL,
  gateway_id TEXT NOT NULL REFERENCES public.payment_gateways(id),
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

CREATE TABLE IF NOT EXISTS public.agency_topup_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID REFERENCES public.agency_topup_requests(id),
  agency_id TEXT NOT NULL,
  gateway_id TEXT,
  amount_usd NUMERIC NOT NULL,
  diamonds NUMERIC NOT NULL,
  approved_by TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.agency_open_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_gateways ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agency_topup_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agency_topup_logs ENABLE ROW LEVEL SECURITY;

-- 4. Create Policies
DROP POLICY IF EXISTS "open_req_read" ON public.agency_open_requests;
CREATE POLICY "open_req_read" ON public.agency_open_requests FOR SELECT USING (true);
DROP POLICY IF EXISTS "open_req_insert" ON public.agency_open_requests;
CREATE POLICY "open_req_insert" ON public.agency_open_requests FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "open_req_update" ON public.agency_open_requests;
CREATE POLICY "open_req_update" ON public.agency_open_requests FOR UPDATE USING (true);

DROP POLICY IF EXISTS "pg_read" ON public.payment_gateways;
CREATE POLICY "pg_read" ON public.payment_gateways FOR SELECT USING (true);

DROP POLICY IF EXISTS "atr_read" ON public.agency_topup_requests;
CREATE POLICY "atr_read" ON public.agency_topup_requests FOR SELECT USING (true);
DROP POLICY IF EXISTS "atr_insert" ON public.agency_topup_requests;
CREATE POLICY "atr_insert" ON public.agency_topup_requests FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "atr_update" ON public.agency_topup_requests;
CREATE POLICY "atr_update" ON public.agency_topup_requests FOR UPDATE USING (true);

DROP POLICY IF EXISTS "atl_read" ON public.agency_topup_logs;
CREATE POLICY "atl_read" ON public.agency_topup_logs FOR SELECT USING (true);
DROP POLICY IF EXISTS "atl_insert" ON public.agency_topup_logs;
CREATE POLICY "atl_insert" ON public.agency_topup_logs FOR INSERT WITH CHECK (true);

-- 5. Grant Permissions to PostgREST (anon, authenticated)
GRANT ALL ON public.agency_open_requests TO anon, authenticated;
GRANT ALL ON public.payment_gateways TO anon, authenticated;
GRANT ALL ON public.agency_topup_requests TO anon, authenticated;
GRANT ALL ON public.agency_topup_logs TO anon, authenticated;

-- 6. Enable Realtime for open requests (used by HostAgencyController)
ALTER PUBLICATION supabase_realtime ADD TABLE public.agency_open_requests;

-- 7. Force Schema Cache Reload (fixes PGRST703)
NOTIFY pgrst, 'reload schema';
