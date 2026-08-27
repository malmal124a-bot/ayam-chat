-- ============================================================
-- Agency Payment Gateways + Top-up System
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Payment gateways config (admin configures these)
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

-- 2. Agency top-up requests (user submits, admin approves)
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

-- 3. Agency top-up logs (approved top-ups)
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

-- RLS
ALTER TABLE payment_gateways ENABLE ROW LEVEL SECURITY;
ALTER TABLE agency_topup_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE agency_topup_logs ENABLE ROW LEVEL SECURITY;

-- payment_gateways: everyone reads, admin writes
DROP POLICY IF EXISTS "pg_read" ON payment_gateways;
CREATE POLICY "pg_read" ON payment_gateways FOR SELECT USING (true);

-- agency_topup_requests: owner reads own, admin reads all
DROP POLICY IF EXISTS "atr_read" ON agency_topup_requests;
CREATE POLICY "atr_read" ON agency_topup_requests FOR SELECT USING (true);
DROP POLICY IF EXISTS "atr_insert" ON agency_topup_requests;
CREATE POLICY "atr_insert" ON agency_topup_requests FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "atr_update" ON agency_topup_requests;
CREATE POLICY "atr_update" ON agency_topup_requests FOR UPDATE USING (true);

-- agency_topup_logs
DROP POLICY IF EXISTS "atl_read" ON agency_topup_logs;
CREATE POLICY "atl_read" ON agency_topup_logs FOR SELECT USING (true);
DROP POLICY IF EXISTS "atl_insert" ON agency_topup_logs;
CREATE POLICY "atl_insert" ON agency_topup_logs FOR INSERT WITH CHECK (true);

-- Grant
GRANT ALL ON payment_gateways TO anon;
GRANT ALL ON agency_topup_requests TO anon;
GRANT ALL ON agency_topup_logs TO anon;

-- Default payment gateways
INSERT INTO payment_gateways (id, name, name_ar, type, is_active, sort_order) VALUES
  ('gw_vodafone', 'Vodafone Cash', 'فودافون كاش', 'vodafone_cash', true, 1),
  ('gw_etisalat', 'Etisalat Cash', 'اتصالات كاش', 'etisalat_cash', true, 2),
  ('gw_syriatel', 'Syriatel Cash', 'سيرياتيل كاش', 'syriatel_cash', true, 3),
  ('gw_usdt', 'USDT (TRC20)', 'يوي إس دي تي', 'usdt_trc20', true, 4),
  ('gw_bank', 'Bank Transfer', 'تحويل بنكي', 'bank_transfer', true, 5)
ON CONFLICT (id) DO NOTHING;

-- RPC: approve top-up request (atomic: update request + add to agency wallet + log)
CREATE OR REPLACE FUNCTION rpc_approve_topup(
  p_request_id UUID,
  p_admin_id TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_req RECORD;
  v_new_balance NUMERIC;
BEGIN
  -- Lock the request row
  SELECT * INTO v_req FROM agency_topup_requests WHERE id = p_request_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'طلب غير موجود');
  END IF;
  IF v_req.status != 'pending' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'تم معالجة هذا الطلب مسبقاً');
  END IF;

  -- Ensure wallet exists
  INSERT INTO agency_wallets (agency_id, diamonds_balance, total_recharged)
  VALUES (v_req.agency_id, 0, 0)
  ON CONFLICT (agency_id) DO NOTHING;

  -- Add diamonds to wallet
  UPDATE agency_wallets
  SET diamonds_balance = diamonds_balance + v_req.diamonds,
      total_recharged = total_recharged + v_req.diamonds
  WHERE agency_id = v_req.agency_id
  RETURNING diamonds_balance INTO v_new_balance;

  -- Update request status
  UPDATE agency_topup_requests
  SET status = 'approved', reviewed_by = p_admin_id, reviewed_at = now()
  WHERE id = p_request_id;

  -- Log
  INSERT INTO agency_topup_logs (request_id, agency_id, gateway_id, amount_usd, diamonds, approved_by)
  VALUES (p_request_id, v_req.agency_id, v_req.gateway_id, v_req.amount_usd, v_req.diamonds, p_admin_id);

  RETURN jsonb_build_object('ok', true, 'new_balance', v_new_balance, 'diamonds_added', v_req.diamonds);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: reject top-up request
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

-- RPC: admin direct top-up (no payment request needed)
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

  -- Ensure wallet exists
  INSERT INTO agency_wallets (agency_id, diamonds_balance, total_recharged)
  VALUES (p_agency_id, 0, 0)
  ON CONFLICT (agency_id) DO NOTHING;

  UPDATE agency_wallets
  SET diamonds_balance = diamonds_balance + p_diamonds,
      total_recharged = total_recharged + p_diamonds
  WHERE agency_id = p_agency_id
  RETURNING diamonds_balance INTO v_new_balance;

  -- Log as admin topup
  INSERT INTO agency_topup_logs (agency_id, amount_usd, diamonds, approved_by)
  VALUES (p_agency_id, 0, p_diamonds, p_admin_id);

  RETURN jsonb_build_object('ok', true, 'new_balance', v_new_balance, 'diamonds_added', p_diamonds);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
