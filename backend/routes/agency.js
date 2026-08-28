const express = require('express');
const router = express.Router();

/**
 * Agency Operations API
 * All routes require JWT authentication.
 * Operations go through Supabase RPC functions (atomic, server-side).
 */
module.exports = function createAgencyRoutes(supabase, authMiddleware) {

  // ─── ALL ROUTES REQUIRE AUTH ───
  router.use(authMiddleware);

  // Auto-create agency_open_requests table if missing (for open-request flow).
  const OPEN_REQUESTS_DDL = `
CREATE TABLE IF NOT EXISTS agency_open_requests (
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
  ON agency_open_requests (requested_by) WHERE status = 'pending';
`;
  async function ensureOpenRequestsTable() {
    if (!supabase || typeof supabase.sql !== 'function') return;
    try { await supabase.sql(OPEN_REQUESTS_DDL); } catch (_) {}
  }

  // ─── GET /api/agency/wallet?agency_id=XXXX ───
  // Get agency wallet balance
  router.get('/wallet', async (req, res) => {
    try {
      const { agency_id } = req.query;
      if (!agency_id) return res.json({ ok: false, error: 'agency_id required' });

      const { data, error } = await supabase
        .from('agency_wallets')
        .select('*')
        .eq('agency_id', agency_id)
        .maybeSingle();

      if (error) throw error;

      // Auto-create wallet if doesn't exist
      if (!data) {
        const { data: newWallet, error: insertErr } = await supabase
          .from('agency_wallets')
          .insert({ agency_id, diamonds_balance: 0 })
          .select()
          .single();
        if (insertErr) throw insertErr;
        return res.json(newWallet);
      }

      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── POST /api/agency/topup ───
  // Top up agency wallet (admin only or self-charge)
  router.post('/topup', async (req, res) => {
    try {
      const { agency_id, diamonds, note } = req.body;
      if (!agency_id || !diamonds || diamonds <= 0) {
        return res.json({ ok: false, error: 'agency_id and diamonds > 0 required' });
      }

      // Upsert wallet
      const { data: existing } = await supabase
        .from('agency_wallets')
        .select('*')
        .eq('agency_id', agency_id)
        .maybeSingle();

      if (existing) {
        const { data, error } = await supabase
          .from('agency_wallets')
          .update({
            diamonds_balance: existing.diamonds_balance + diamonds,
            updated_at: new Date().toISOString(),
          })
          .eq('agency_id', agency_id)
          .select()
          .single();
        if (error) throw error;
        return res.json(data);
      } else {
        const { data, error } = await supabase
          .from('agency_wallets')
          .insert({ agency_id, diamonds_balance: diamonds })
          .select()
          .single();
        if (error) throw error;
        return res.json(data);
      }
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── POST /api/agency/recharge ───
  // Agent charges a user with diamonds (atomic RPC)
  router.post('/recharge', async (req, res) => {
    try {
      const { agency_id, target_user_id, target_numeric_id, diamonds, cost_diamonds } = req.body;
      const agent_uid = req.user.sub;

      if (!agency_id || !target_user_id || !diamonds || diamonds <= 0) {
        return res.json({ ok: false, error: 'Missing required fields' });
      }
      if (!cost_diamonds || cost_diamonds <= 0) {
        return res.json({ ok: false, error: 'cost_diamonds required' });
      }

      // Try RPC first
      const { data, error } = await supabase.rpc('rpc_agency_recharge', {
        p_agency_id: agency_id,
        p_agent_uid: agent_uid,
        p_target_uid: target_user_id,
        p_target_numeric_id: target_numeric_id || null,
        p_diamonds: diamonds,
        p_cost_diamonds: cost_diamonds,
      });

      if (!error && data?.ok) return res.json(data);

      // Fallback: direct operations
      const { data: wallet } = await supabase.from('agency_wallets')
        .select('diamonds_balance').eq('agency_id', agency_id).maybeSingle();
      if (!wallet || (wallet.diamonds_balance ?? 0) < cost_diamonds) {
        return res.json({ ok: false, error: 'رصيد الوكالة غير كافٍ' });
      }

      const { error: deductErr } = await supabase.from('agency_wallets').update({
        diamonds_balance: wallet.diamonds_balance - cost_diamonds,
        updated_at: new Date().toISOString(),
      }).eq('agency_id', agency_id);
      if (deductErr) throw deductErr;

      const { data: targetUser } = await supabase.from('users')
        .select('auth_uid, diamonds').eq('auth_uid', target_user_id).maybeSingle();
      if (!targetUser) {
        await supabase.from('agency_wallets').update({
          diamonds_balance: wallet.diamonds_balance,
        }).eq('agency_id', agency_id);
        return res.json({ ok: false, error: 'المستخدم غير موجود' });
      }

      const { error: addErr } = await supabase.from('users').update({
        diamonds: (targetUser.diamonds ?? 0) + diamonds,
      }).eq('auth_uid', target_user_id);
      if (addErr) throw addErr;

      await supabase.from('agency_recharges').insert({
        agency_id, agent_user_id: agent_uid, target_user_id,
        target_numeric_id: target_numeric_id || null,
        diamonds, cost_diamonds, status: 'completed',
      });

      const remaining = wallet.diamonds_balance - cost_diamonds;
      res.json({ ok: true, diamonds_charged: diamonds, cost_diamonds, remaining_balance: remaining });
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── POST /api/agency/withdraw ───
  // Withdraw diamonds from user to agency wallet (atomic RPC)
  router.post('/withdraw', async (req, res) => {
    try {
      const { agency_id, source_user_id, source_numeric_id, diamonds } = req.body;
      const agent_uid = req.user.sub;

      if (!agency_id || !source_user_id || !diamonds || diamonds <= 0) {
        return res.json({ ok: false, error: 'Missing required fields' });
      }

      // Try RPC first
      const { data, error } = await supabase.rpc('rpc_agency_withdraw', {
        p_agency_id: agency_id,
        p_agent_uid: agent_uid,
        p_source_uid: source_user_id,
        p_source_numeric_id: source_numeric_id || null,
        p_diamonds: diamonds,
      });

      if (!error && data?.ok) return res.json(data);

      // Fallback: direct operations
      const { data: sourceUser } = await supabase.from('users')
        .select('auth_uid, diamonds').eq('auth_uid', source_user_id).maybeSingle();
      if (!sourceUser) return res.json({ ok: false, error: 'المستخدم غير موجود' });
      if ((sourceUser.diamonds ?? 0) < diamonds) return res.json({ ok: false, error: 'رصيد المستخدم غير كافٍ' });

      // Deduct from user
      await supabase.from('users').update({ diamonds: sourceUser.diamonds - diamonds }).eq('auth_uid', source_user_id);

      // Add to agency wallet
      const { data: wallet } = await supabase.from('agency_wallets')
        .select('diamonds_balance').eq('agency_id', agency_id).maybeSingle();
      if (!wallet) {
        await supabase.from('agency_wallets').insert({ agency_id, diamonds_balance: diamonds, total_withdrawn: diamonds });
      } else {
        await supabase.from('agency_wallets').update({
          diamonds_balance: (wallet.diamonds_balance ?? 0) + diamonds,
          total_withdrawn: (wallet.total_withdrawn ?? 0) + diamonds,
        }).eq('agency_id', agency_id);
      }

      // Log
      await supabase.from('agency_withdrawals').insert({
        agency_id, agent_user_id: agent_uid, source_user_id,
        source_numeric_id: source_numeric_id || null, diamonds, status: 'completed',
      });

      const newBalance = (wallet?.diamonds_balance ?? 0) + diamonds;
      res.json({ ok: true, new_balance: newBalance, diamonds_withdrawn: diamonds });
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── POST /api/agency/salary/calculate ───
  // Calculate salaries for agency members
  router.post('/salary/calculate', async (req, res) => {
    try {
      const { agency_id, user_ids, period_start, period_end } = req.body;
      const agent_uid = req.user.sub;

      if (!agency_id || !user_ids || !Array.isArray(user_ids) || user_ids.length === 0) {
        return res.json({ ok: false, error: 'agency_id and user_ids[] required' });
      }

      const { data, error } = await supabase.rpc('rpc_agency_calculate_salary', {
        p_agency_id: agency_id,
        p_agent_uid: agent_uid,
        p_user_ids: user_ids,
        p_period_start: period_start || new Date(Date.now() - 30 * 86400000).toISOString(),
        p_period_end: period_end || new Date().toISOString(),
      });

      if (error) throw error;
      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── POST /api/agency/salary/pay ───
  // Pay a single salary item
  router.post('/salary/pay', async (req, res) => {
    try {
      const { item_id, agency_id } = req.body;

      if (!item_id || !agency_id) {
        return res.json({ ok: false, error: 'item_id and agency_id required' });
      }

      const { data, error } = await supabase.rpc('rpc_agency_pay_salary_item', {
        p_item_id: item_id,
        p_agency_id: agency_id,
      });

      if (error) throw error;
      if (!data.ok) return res.json({ ok: false, ...data });
      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── POST /api/agency/salary/pay-all ───
  // Pay all pending salary items in a run
  router.post('/salary/pay-all', async (req, res) => {
    try {
      const { run_id, agency_id } = req.body;

      if (!run_id || !agency_id) {
        return res.json({ ok: false, error: 'run_id and agency_id required' });
      }

      // Fetch all pending items
      const { data: items, error: fetchErr } = await supabase
        .from('agency_salary_items')
        .select('*')
        .eq('run_id', run_id)
        .eq('status', 'pending');

      if (fetchErr) throw fetchErr;

      const results = [];
      let paid = 0, failed = 0;

      for (const item of items || []) {
        const { data, error } = await supabase.rpc('rpc_agency_pay_salary_item', {
          p_item_id: item.id,
          p_agency_id: agency_id,
        });
        if (data?.ok) paid++;
        else failed++;
        results.push({ user_id: item.user_id, ok: data?.ok, error: data?.error });
      }

      // Update run status
      if (failed === 0 && items?.length > 0) {
        await supabase
          .from('agency_salary_runs')
          .update({ status: 'paid' })
          .eq('id', run_id);
      }

      res.json({ ok: true, paid, failed, results });
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── GET /api/agency/logs/recharges?agency_id=XXXX&limit=50 ───
  router.get('/logs/recharges', async (req, res) => {
    try {
      const { agency_id, limit = 50 } = req.query;
      if (!agency_id) return res.json({ ok: false, error: 'agency_id required' });

      const { data, error } = await supabase
        .from('agency_recharges')
        .select('*')
        .eq('agency_id', agency_id)
        .order('created_at', { ascending: false })
        .limit(Number(limit));

      if (error) throw error;
      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── GET /api/agency/logs/withdrawals?agency_id=XXXX&limit=50 ───
  router.get('/logs/withdrawals', async (req, res) => {
    try {
      const { agency_id, limit = 50 } = req.query;
      if (!agency_id) return res.json({ ok: false, error: 'agency_id required' });

      const { data, error } = await supabase
        .from('agency_withdrawals')
        .select('*')
        .eq('agency_id', agency_id)
        .order('created_at', { ascending: false })
        .limit(Number(limit));

      if (error) throw error;
      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── GET /api/agency/salary/runs?agency_id=XXXX ───
  router.get('/salary/runs', async (req, res) => {
    try {
      const { agency_id } = req.query;
      if (!agency_id) return res.json({ ok: false, error: 'agency_id required' });

      const { data, error } = await supabase
        .from('agency_salary_runs')
        .select('*')
        .eq('agency_id', agency_id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── GET /api/agency/salary/items?run_id=XXXX ───
  router.get('/salary/items', async (req, res) => {
    try {
      const { run_id } = req.query;
      if (!run_id) return res.json({ ok: false, error: 'run_id required' });

      const { data, error } = await supabase
        .from('agency_salary_items')
        .select('*')
        .eq('run_id', run_id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── GET /api/agency/user/:uid/balance ───
  // Get a user's diamonds balance (for agent to check before recharge)
  router.get('/user/:uid/balance', async (req, res) => {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('auth_uid, numeric_id, name, diamonds, coins, photo_url')
        .or(`auth_uid.eq.${req.params.uid},numeric_id.eq.${req.params.uid}`)
        .maybeSingle();

      if (error) throw error;
      if (!data) return res.json({ ok: false, error: 'User not found' });
      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── GET /api/agency/members?agency_id=XXXX ───
  router.get('/members', async (req, res) => {
    try {
      const { agency_id } = req.query;
      if (!agency_id) return res.json({ ok: false, error: 'agency_id required' });

      const { data: members, error } = await supabase
        .from('host_agency_members')
        .select('*')
        .eq('agency_id', agency_id);

      if (error) throw error;
      if (!members || members.length === 0) return res.json([]);

      const userIds = [...new Set(members.map(m => m.user_id).filter(Boolean))];
      let usersMap = {};
      if (userIds.length > 0) {
        const { data: users } = await supabase
          .from('users')
          .select('auth_uid, numeric_id, name, photo_url, diamonds')
          .in('auth_uid', userIds);
        if (users) users.forEach(u => { usersMap[u.auth_uid] = u; });
      }

      const enriched = members.map(m => ({
        ...m,
        users: usersMap[m.user_id] || null,
        name: usersMap[m.user_id]?.name,
        numeric_id: usersMap[m.user_id]?.numeric_id,
        photo_url: usersMap[m.user_id]?.photo_url,
        diamonds: usersMap[m.user_id]?.diamonds,
      }));
      res.json(enriched);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── POST /api/agency/open-for-user ───
  // Open an agency for a user by their numeric_id + create auth account + send notification
  router.post('/open-for-user', async (req, res) => {
    try {
      const { target_numeric_id, agency_name, agency_type } = req.body;
      const agent_uid = req.user.sub;

      if (!target_numeric_id) {
        return res.json({ ok: false, error: 'target_numeric_id required' });
      }

      // 1. Call RPC to create agency + wallet + notification
      const { data, error } = await supabase.rpc('rpc_open_agency_for_user', {
        p_target_numeric_id: target_numeric_id,
        p_agency_name: agency_name || '',
        p_agency_type: agency_type || 'shipping',
        p_agent_uid: agent_uid,
      });

      if (error) throw error;
      if (!data.ok) return res.json({ ok: false, ...data });

      // 2. Create Supabase auth account for the agency owner
      const email = `${target_numeric_id}@ayam.chat`;
      const password = `ayam${target_numeric_id}`;
      let authCreated = false;
      let authError = null;

      try {
        const { data: authData, error: createErr } = await supabase.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
          user_metadata: {
            numeric_id: target_numeric_id,
            agency_id: data.agency_id,
            name: data.user_name || '',
          },
        });

        if (createErr) {
          // If user already exists, that's OK
          if (createErr.message?.includes('already') || createErr.message?.includes('exists')) {
            authCreated = true;
          } else {
            authError = createErr.message;
          }
        } else {
          authCreated = true;
        }
      } catch (e) {
        authError = e.message;
      }

      res.json({
        ...data,
        auth_created: authCreated,
        auth_error: authError,
        dashboard_email: email,
        dashboard_password: password,
        dashboard_agency_id: data.agency_id,
      });
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── GET /api/agency/my-agency?owner_uid=XXXX ───
  // Get agency by owner auth_uid OR numeric_id (for loading from Supabase)
  router.get('/my-agency', async (req, res) => {
    try {
      const { owner_uid } = req.query;
      if (!owner_uid) return res.json({ ok: false, error: 'owner_uid required' });

      // Try direct match first (auth_uid)
      let { data, error } = await supabase
        .from('agencies')
        .select('*')
        .eq('owner_id', owner_uid)
        .eq('is_activated', true)
        .maybeSingle();

      // If not found, try by numeric_id (look up auth_uid first)
      if (!data && !error) {
        const { data: user } = await supabase
          .from('users')
          .select('auth_uid')
          .eq('numeric_id', owner_uid)
          .maybeSingle();

        if (user) {
          const result = await supabase
            .from('agencies')
            .select('*')
            .eq('owner_id', user.auth_uid)
            .eq('is_activated', true)
            .maybeSingle();
          data = result.data;
          error = result.error;
        }
      }

      if (error) throw error;
      if (!data) return res.json({ ok: false, error: 'No active agency found' });
      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── PAYMENT GATEWAYS ───────────────────────────────

  // GET /api/agency/payment-gateways — list active gateways
  router.get('/payment-gateways', async (req, res) => {
    try {
      const { data, error } = await supabase
        .from('payment_gateways')
        .select('*')
        .eq('is_active', true)
        .order('sort_order');
      if (error) throw error;
      res.json(data || []);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // GET /api/agency/payment-gateways/all — admin: list all gateways
  router.get('/payment-gateways/all', async (req, res) => {
    try {
      const { data, error } = await supabase
        .from('payment_gateways')
        .select('*')
        .order('sort_order');
      if (error) throw error;
      res.json(data || []);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── TOP-UP REQUESTS ───────────────────────────────

  // POST /api/agency/topup-request — user submits a top-up request
  router.post('/topup-request', async (req, res) => {
    try {
      const { agency_id, gateway_id, amount_usd, diamonds, sender_number, transaction_ref } = req.body;
      if (!agency_id || !gateway_id || !amount_usd || !diamonds) {
        return res.json({ ok: false, error: 'Missing required fields' });
      }
      if (amount_usd <= 0 || diamonds <= 0) {
        return res.json({ ok: false, error: 'Amount must be > 0' });
      }

      const { data, error } = await supabase
        .from('agency_topup_requests')
        .insert({
          agency_id,
          owner_uid: req.user.sub,
          gateway_id,
          amount_usd,
          diamonds,
          sender_number: sender_number || '',
          transaction_ref: transaction_ref || '',
        })
        .select('*')
        .single();
      if (error) throw error;
      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // GET /api/agency/topup-requests — list requests
  router.get('/topup-requests', async (req, res) => {
    try {
      const { status, agency_id } = req.query;
      let query = supabase.from('agency_topup_requests').select('*').order('created_at', { ascending: false });
      if (status) query = query.eq('status', status);
      if (agency_id) query = query.eq('agency_id', agency_id);
      const { data, error } = await query;
      if (error) throw error;
      res.json(data || []);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // POST /api/agency/topup-approve — admin approves a request
  router.post('/topup-approve', async (req, res) => {
    try {
      const { request_id } = req.body;
      if (!request_id) return res.json({ ok: false, error: 'request_id required' });

      // Try RPC first
      const { data: rpcResult, error: rpcError } = await supabase.rpc('rpc_approve_topup', {
        p_request_id: request_id,
        p_admin_id: req.user.sub,
      });
      if (!rpcError && rpcResult?.ok) return res.json(rpcResult);

      // Fallback: direct operations
      const { data: reqData, error: reqErr } = await supabase
        .from('agency_topup_requests').select('*').eq('id', request_id).single();
      if (reqErr || !reqData) return res.json({ ok: false, error: 'طلب غير موجود' });
      if (reqData.status !== 'pending') return res.json({ ok: false, error: 'تم معالجة هذا الطلب مسبقاً' });

      // Ensure wallet exists (don't reset balance)
      const { data: existing } = await supabase.from('agency_wallets')
        .select('*').eq('agency_id', reqData.agency_id).maybeSingle();

      let newBalance;
      if (!existing) {
        newBalance = reqData.diamonds;
        await supabase.from('agency_wallets').insert({
          agency_id: reqData.agency_id, diamonds_balance: newBalance,
          total_recharged: newBalance, total_withdrawn: 0,
        });
      } else {
        newBalance = (existing.diamonds_balance ?? 0) + reqData.diamonds;
        await supabase.from('agency_wallets').update({
          diamonds_balance: newBalance,
          total_recharged: (existing.total_recharged ?? 0) + reqData.diamonds,
        }).eq('agency_id', reqData.agency_id);
      }

      await supabase.from('agency_topup_requests').update({
        status: 'approved', reviewed_by: req.user.sub, reviewed_at: new Date().toISOString(),
      }).eq('id', request_id);

      await supabase.from('agency_topup_logs').insert({
        request_id, agency_id: reqData.agency_id, gateway_id: reqData.gateway_id,
        amount_usd: reqData.amount_usd, diamonds: reqData.diamonds, approved_by: req.user.sub,
      });

      res.json({ ok: true, new_balance: newBalance, diamonds_added: reqData.diamonds });
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // POST /api/agency/topup-reject — admin rejects a request
  router.post('/topup-reject', async (req, res) => {
    try {
      const { request_id, reason } = req.body;
      if (!request_id) return res.json({ ok: false, error: 'request_id required' });

      const { data, error } = await supabase
        .from('agency_topup_requests')
        .update({ status: 'rejected', admin_note: reason || '', reviewed_by: req.user.sub, reviewed_at: new Date().toISOString() })
        .eq('id', request_id)
        .eq('status', 'pending')
        .select('*')
        .single();
      if (error) throw error;
      if (!data) return res.json({ ok: false, error: 'طلب غير موجود أو تم معالجته' });
      res.json({ ok: true });
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // POST /api/agency/admin-topup — admin directly top-ups agency (no request)
  router.post('/admin-topup', async (req, res) => {
    try {
      const { agency_id, diamonds } = req.body;
      if (!agency_id || !diamonds || diamonds <= 0) {
        return res.json({ ok: false, error: 'agency_id and diamonds > 0 required' });
      }

      // Ensure wallet exists (don't reset balance)
      const { data: existing } = await supabase.from('agency_wallets')
        .select('*').eq('agency_id', agency_id).maybeSingle();

      let newBalance;
      if (!existing) {
        newBalance = diamonds;
        await supabase.from('agency_wallets').insert({
          agency_id, diamonds_balance: newBalance, total_recharged: newBalance, total_withdrawn: 0,
        });
      } else {
        newBalance = (existing.diamonds_balance ?? 0) + diamonds;
        await supabase.from('agency_wallets').update({
          diamonds_balance: newBalance,
          total_recharged: (existing.total_recharged ?? 0) + diamonds,
        }).eq('agency_id', agency_id);
      }

      await supabase.from('agency_topup_logs').insert({
        agency_id, amount_usd: 0, diamonds, approved_by: req.user.sub,
      });

      res.json({ ok: true, new_balance: newBalance, diamonds_added: diamonds });
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // GET /api/agency/topup-logs — top-up history
  router.get('/topup-logs', async (req, res) => {
    try {
      const { agency_id } = req.query;
      let query = supabase.from('agency_topup_logs').select('*').order('created_at', { ascending: false }).limit(100);
      if (agency_id) query = query.eq('agency_id', agency_id);
      const { data, error } = await query;
      if (error) throw error;
      res.json(data || []);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── AGENCY PROFILE ───────────────────────────────

  // GET /api/agency/profile?agency_id=XXXX
  router.get('/profile', async (req, res) => {
    try {
      const { agency_id } = req.query;
      if (!agency_id) return res.json({ ok: false, error: 'agency_id required' });
      const { data, error } = await supabase.from('agencies').select('*').eq('id', agency_id).maybeSingle();
      if (error) throw error;
      if (!data) return res.json({ ok: false, error: 'Agency not found' });
      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // PUT /api/agency/profile — update name + photo
  router.put('/profile', async (req, res) => {
    try {
      const { agency_id, name, photo_url } = req.body;
      if (!agency_id) return res.json({ ok: false, error: 'agency_id required' });

      const updates = {};
      if (name !== undefined) updates.name = name;
      if (photo_url !== undefined) updates.photo_url = photo_url;
      updates.updated_at = new Date().toISOString();

      const { data, error } = await supabase
        .from('agencies')
        .update(updates)
        .eq('id', agency_id)
        .select('*')
        .single();
      if (error) throw error;
      res.json(data);
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── INVITE MEMBER ───────────────────────────────

  // POST /api/agency/invite-member — send invitation to a user by numeric_id
  router.post('/invite-member', async (req, res) => {
    try {
      const { agency_id, target_numeric_id } = req.body;
      const agent_uid = req.user.sub;
      if (!agency_id || !target_numeric_id) {
        return res.json({ ok: false, error: 'agency_id and target_numeric_id required' });
      }

      // 1. Find target user
      const { data: targetUser, error: userErr } = await supabase
        .from('users')
        .select('auth_uid, numeric_id, name')
        .eq('numeric_id', target_numeric_id)
        .maybeSingle();
      if (userErr || !targetUser) {
        return res.json({ ok: false, error: 'المستخدم غير موجود بهذا الرقم' });
      }

      // 2. Check if already a member
      const { data: existingMember } = await supabase
        .from('host_agency_members')
        .select('id')
        .eq('agency_id', agency_id)
        .eq('user_id', targetUser.auth_uid)
        .eq('status', 'active')
        .maybeSingle();
      if (existingMember) {
        return res.json({ ok: false, error: 'العضو موجود بالفعل في الوكالة' });
      }

      // 3. Check if already has pending/invited request
      const { data: existingRequest } = await supabase
        .from('host_agency_join_requests')
        .select('id')
        .eq('agency_id', agency_id)
        .eq('user_id', targetUser.auth_uid)
        .in('status', ['pending', 'invited'])
        .maybeSingle();
      if (existingRequest) {
        return res.json({ ok: false, error: 'تم إرسال دعوة بالفعل لهذا المستخدم' });
      }

      // 4. Get agency name for notification
      const { data: agency } = await supabase
        .from('agencies')
        .select('name')
        .eq('id', agency_id)
        .maybeSingle();

      // 5. Get agent name
      const { data: agentUser } = await supabase
        .from('users')
        .select('name')
        .eq('auth_uid', agent_uid)
        .maybeSingle();

      // 6. Create join request with status 'invited'
      const { error: insertErr } = await supabase
        .from('host_agency_join_requests')
        .insert({
          agency_id,
          user_id: targetUser.auth_uid,
          status: 'invited',
          message: `دعوة من الوكالة: ${agency?.name || agency_id}`,
        });
      if (insertErr) throw insertErr;

      // 7. Send DM notification to the invited user
      await supabase.from('dm_messages').insert({
        from_user_id: agent_uid,
        to_user_id: target_numeric_id,
        from_name: agentUser?.name || 'الوكيل',
        to_name: targetUser.name || target_numeric_id,
        text: `📩 لديك دعوة للانضمام إلى الوكالة "${agency?.name || agency_id}"! افتح شاشة الوكالة لقبول أو رفض الدعوة.`,
        is_read: false,
      });

      res.json({ ok: true, message: 'تم إرسال الدعوة بنجاح' });
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── REMOVE MEMBER ───────────────────────────────

  // DELETE /api/agency/remove-member — remove a member from agency
  router.delete('/remove-member', async (req, res) => {
    try {
      const { agency_id, user_id } = req.body;
      if (!agency_id || !user_id) {
        return res.json({ ok: false, error: 'agency_id and user_id required' });
      }

      // 1. Update member status to 'removed'
      const { error: updateErr } = await supabase
        .from('host_agency_members')
        .update({ status: 'removed' })
        .eq('agency_id', agency_id)
        .eq('user_id', user_id);
      if (updateErr) throw updateErr;

      // 2. Send DM notification to removed user
      const { data: removedUser } = await supabase
        .from('users')
        .select('numeric_id, name')
        .eq('auth_uid', user_id)
        .maybeSingle();

      const { data: agency } = await supabase
        .from('agencies')
        .select('name')
        .eq('id', agency_id)
        .maybeSingle();

      if (removedUser) {
        await supabase.from('dm_messages').insert({
          from_user_id: 'system',
          to_user_id: removedUser.numeric_id,
          from_name: 'النظام',
          to_name: removedUser.name || removedUser.numeric_id,
          text: `تم إزالتك من الوكالة "${agency?.name || agency_id}". يمكنك التواصل مع الإدارة لمعرفة التفاصيل.`,
          is_read: false,
        });
      }

      res.json({ ok: true, message: 'تم إزالة العضو بنجاح' });
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // ─── HOST AGENCY OPEN REQUESTS (approval-gated) ──────────

  // POST /api/agency/open-request — a user submits their own hosting-agency open request
  router.post('/open-request', async (req, res) => {
    try {
      const agent_uid = req.user.sub;
      await ensureOpenRequestsTable();
      const { agency_name, phone, agency_id, photo_url, id_card_url } = req.body;
      if (!agency_name || !agency_id) {
        return res.json({ ok: false, error: 'agency_name and agency_id required' });
      }

      // Already has an active agency?
      const { data: existingAgency } = await supabase
        .from('agencies')
        .select('id')
        .eq('owner_id', agent_uid)
        .eq('is_activated', true)
        .maybeSingle();
      if (existingAgency) {
        return res.json({ ok: false, error: 'لديك وكالة مفعّلة بالفعل' });
      }

      // Already has a pending request?
      const { data: pendingReq } = await supabase
        .from('agency_open_requests')
        .select('id, status')
        .eq('requested_by', agent_uid)
        .eq('status', 'pending')
        .maybeSingle();
      if (pendingReq) {
        return res.json({ ok: false, error: 'لديك طلب قيد المراجعة بالفعل', request_id: pendingReq.id });
      }

      const { data, error } = await supabase
        .from('agency_open_requests')
        .insert({
          requested_by: agent_uid,
          agency_name,
          phone: phone || '',
          agency_id: String(agency_id),
          photo_url: photo_url || '',
          id_card_url: id_card_url || '',
          agency_type: 'hosting',
          status: 'pending',
        })
        .select()
        .single();
      if (error) throw error;

      res.json({ ok: true, request: data });
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  // GET /api/agency/my-open-request — get the caller's latest open request
  router.get('/my-open-request', async (req, res) => {
    try {
      const agent_uid = req.user.sub;
      await ensureOpenRequestsTable();
      const { data, error } = await supabase
        .from('agency_open_requests')
        .select('*')
        .eq('requested_by', agent_uid)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();
      if (error) throw error;
      res.json({ ok: true, request: data || null });
    } catch (e) { res.json({ ok: false, error: e.message }); }
  });

  return router;
};
