const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const { authMiddleware } = require('../auth');
const createAgencyRoutes = require('../routes/agency');

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const supabase = SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
  ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    })
  : null;

// Auto-create the agency_open_requests table (and index) if it doesn't exist.
// Uses supabase.sql() (PostgREST SQL endpoint) which requires the service role.
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
const ensureOpenRequestsTableBefore = (handler) => async (req, res) => {
  try { await ensureOpenRequestsTable(); } catch (_) {}
  return handler(req, res);
};

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', supabase: supabase ? 'connected' : 'missing_config' });
});

app.get('/', (_req, res) => {
  res.json({
    name: 'Ayam Chat API',
    version: '2.0',
    deployment: 'vercel',
    endpoints: [
      '/health', '/api/users', '/api/agencies', '/api/medals', '/api/rooms',
      '/api/store_items', '/api/banners', '/api/dm_messages', '/api/dashboard/stats',
      '/api/agency/* (auth required)',
      '/api/admin/* (admin key required)',
    ],
  });
});

// ---------- AGENCY ROUTES (JWT auth required) ----------
if (supabase) {
  app.use('/api/agency', createAgencyRoutes(supabase, authMiddleware()));
}

// ---------- USERS ----------
app.get('/api/users', async (req, res) => {
  try {
    const { data, error } = await supabase.from('users').select('*');
    if (error) throw error;
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.get('/api/users/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users').select('*')
      .or(`auth_uid.eq.${req.params.id},numeric_id.eq.${req.params.id}`)
      .maybeSingle();
    if (error) throw error;
    if (!data) return res.json({ ok: false, error: 'User not found' });
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.post('/api/users', async (req, res) => {
  try {
    const { data, error } = await supabase.from('users').insert(req.body).select().single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.patch('/api/users/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users').update(req.body)
      .or(`auth_uid.eq.${req.params.id},numeric_id.eq.${req.params.id}`)
      .select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// ---------- AGENCIES ----------
app.get('/api/agencies', async (req, res) => {
  try {
    const { data, error } = await supabase.from('agencies').select('*');
    if (error) throw error;
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.get('/api/agencies/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('agencies').select('*').eq('id', req.params.id).maybeSingle();
    if (error) throw error;
    if (!data) return res.json({ ok: false, error: 'Agency not found' });
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.post('/api/agencies', async (req, res) => {
  try {
    const { data, error } = await supabase.from('agencies').insert(req.body).select().single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.patch('/api/agencies/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('agencies').update(req.body).eq('id', req.params.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// ---------- MEDALS ----------
app.get('/api/medals', async (req, res) => {
  try {
    const { data, error } = await supabase.from('medals').select('*').order('order');
    if (error) throw error;
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// ---------- ROOMS ----------
app.get('/api/rooms', async (req, res) => {
  try {
    const { data, error } = await supabase.from('rooms').select('*');
    if (error) throw error;
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.get('/api/rooms/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('rooms').select('*').eq('room_id', req.params.id).maybeSingle();
    if (error) throw error;
    if (!data) return res.json({ ok: false, error: 'Room not found' });
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.patch('/api/rooms/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('rooms').update(req.body).eq('room_id', req.params.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// ---------- STORE ITEMS ----------
app.get('/api/store_items', async (req, res) => {
  try {
    const { data, error } = await supabase.from('store_items').select('*').order('order');
    if (error) throw error;
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.post('/api/store_items', async (req, res) => {
  try {
    const item = { ...req.body, updated_at: new Date().toISOString() };
    if (!item.id) { item.id = `item_${Date.now()}`; item.created_at = new Date().toISOString(); }
    const { data, error } = await supabase
      .from('store_items').upsert(item, { onConflict: 'id' }).select().single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.patch('/api/store_items/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('store_items').update({ ...req.body, updated_at: new Date().toISOString() })
      .eq('id', req.params.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.delete('/api/store_items/:id', async (req, res) => {
  try {
    const { error } = await supabase.from('store_items').delete().eq('id', req.params.id);
    if (error) throw error;
    res.json({ ok: true });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// ---------- BANNERS ----------
app.get('/api/banners', async (req, res) => {
  try {
    const { data, error } = await supabase.from('banners').select('*').order('order');
    if (error) throw error;
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.post('/api/banners', async (req, res) => {
  try {
    const banner = req.body;
    if (!banner.id) banner.id = crypto.randomUUID();
    const { data, error } = await supabase
      .from('banners').upsert(banner, { onConflict: 'id' }).select().single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.delete('/api/banners/:id', async (req, res) => {
  try {
    const { error } = await supabase.from('banners').delete().eq('id', req.params.id);
    if (error) throw error;
    res.json({ ok: true });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// ---------- DIRECT MESSAGES ----------
app.get('/api/dm_messages', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('dm_messages').select('*').order('created_at', { ascending: false }).limit(500);
    if (error) throw error;
    res.json(data);
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// ---------- ADMIN OPERATIONS (service-role required) ----------
const ADMIN_SECRET = process.env.ADMIN_SECRET || 'ayam-admin';
function adminAuth(req, res) {
  const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, '').trim();
  if (!token) { return false; }
  if (token === SUPABASE_SERVICE_ROLE_KEY || token === ADMIN_SECRET) return true;
  return false;
}

app.post('/api/admin/delete-agency', async (req, res) => {
  try {
    if (!adminAuth(req, res)) return res.json({ ok: false, error: 'Forbidden' });
    const { agency_id } = req.body;
    if (!agency_id) return res.json({ ok: false, error: 'agency_id required' });

    const { data: agency } = await supabase.from('agencies').select('owner_id, name').eq('id', agency_id).single();
    if (!agency) return res.json({ ok: false, error: 'Agency not found' });

    await supabase.from('agency_wallets').delete().eq('agency_id', agency_id);
    await supabase.from('agency_topup_requests').delete().eq('agency_id', agency_id);
    await supabase.from('agency_topup_logs').delete().eq('agency_id', agency_id);
    await supabase.from('host_agency_members').delete().eq('agency_id', agency_id);
    await supabase.from('host_agency_join_requests').delete().eq('agency_id', agency_id);

    await supabase.from('agencies').delete().eq('id', agency_id);

    if (agency.owner_id) {
      try { await supabase.auth.admin.deleteUser(agency.owner_id); } catch {}
    }

    res.json({ ok: true });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.post('/api/admin/topup-approve', async (req, res) => {
  try {
    if (!adminAuth(req, res)) return res.json({ ok: false, error: 'Forbidden' });
    const { request_id } = req.body;
    if (!request_id) return res.json({ ok: false, error: 'request_id required' });

    const { data: topupReq, error: rErr } = await supabase.from('agency_topup_requests').select('*').eq('id', request_id).single();
    if (rErr || !topupReq) return res.json({ ok: false, error: 'Request not found' });
    if (topupReq.status !== 'pending') return res.json({ ok: false, error: 'Already processed' });

    const { data: existing } = await supabase.from('agency_wallets').select('*').eq('agency_id', topupReq.agency_id).maybeSingle();
    if (!existing) {
      await supabase.from('agency_wallets').insert({ agency_id: topupReq.agency_id, diamonds_balance: topupReq.diamonds, total_recharged: topupReq.diamonds, total_withdrawn: 0 });
    } else {
      await supabase.from('agency_wallets').update({
        diamonds_balance: (existing.diamonds_balance ?? 0) + topupReq.diamonds,
        total_recharged: (existing.total_recharged ?? 0) + topupReq.diamonds,
      }).eq('agency_id', topupReq.agency_id);
    }

    await supabase.from('agency_topup_requests').update({ status: 'approved', reviewed_by: 'admin', reviewed_at: new Date().toISOString() }).eq('id', request_id);
    await supabase.from('agency_topup_logs').insert({ request_id, agency_id: topupReq.agency_id, gateway_id: topupReq.gateway_id, amount_usd: topupReq.amount_usd, diamonds: topupReq.diamonds, approved_by: 'admin' });

    const { data: finalWallet } = await supabase.from('agency_wallets').select('diamonds_balance').eq('agency_id', topupReq.agency_id).single();
    res.json({ ok: true, diamonds_balance: finalWallet?.diamonds_balance ?? 0 });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.post('/api/admin/topup-reject', async (req, res) => {
  try {
    if (!adminAuth(req, res)) return res.json({ ok: false, error: 'Forbidden' });
    const { request_id, note } = req.body;
    if (!request_id) return res.json({ ok: false, error: 'request_id required' });

    await supabase.from('agency_topup_requests').update({ status: 'rejected', admin_note: note || '', reviewed_by: 'admin', reviewed_at: new Date().toISOString() }).eq('id', request_id).eq('status', 'pending');
    res.json({ ok: true });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.post('/api/admin/topup-direct', async (req, res) => {
  try {
    if (!adminAuth(req, res)) return res.json({ ok: false, error: 'Forbidden' });
    const { agency_id, diamonds } = req.body;
    if (!agency_id || !diamonds || diamonds <= 0) return res.json({ ok: false, error: 'agency_id and diamonds required' });

    const { data: existing } = await supabase.from('agency_wallets').select('*').eq('agency_id', agency_id).maybeSingle();
    if (!existing) {
      await supabase.from('agency_wallets').insert({ agency_id, diamonds_balance: diamonds, total_recharged: diamonds, total_withdrawn: 0 });
    } else {
      await supabase.from('agency_wallets').update({
        diamonds_balance: (existing.diamonds_balance ?? 0) + diamonds,
        total_recharged: (existing.total_recharged ?? 0) + diamonds,
      }).eq('agency_id', agency_id);
    }

    await supabase.from('agency_topup_logs').insert({ agency_id, amount_usd: 0, diamonds, approved_by: 'admin' });

    const { data: finalWallet } = await supabase.from('agency_wallets').select('diamonds_balance').eq('agency_id', agency_id).single();
    res.json({ ok: true, diamonds_balance: finalWallet?.diamonds_balance ?? 0 });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.post('/api/admin/open-agency', async (req, res) => {
  try {
    if (!adminAuth(req, res)) return res.json({ ok: false, error: 'Forbidden' });
    const { numeric_id, agency_type, agency_name } = req.body;
    if (!numeric_id) return res.json({ ok: false, error: 'numeric_id required' });

    const agencyId = `AG${numeric_id}`;
    const type = agency_type || 'shipping';
    const name = agency_name || `وكالة ${numeric_id}`;
    const email = `${numeric_id}@ayam.chat`;
    const password = `ayam${numeric_id}`;

    const { data: existing } = await supabase.from('agencies').select('id, owner_id').eq('id', agencyId).maybeSingle();
    if (existing) {
      // Agency already exists — but ensure auth user exists for owner
      if (existing.owner_id) {
        const { data: existingAuth } = await supabase.auth.admin.getUserById(existing.owner_id);
        if (!existingAuth?.user) {
          const { data: authUser } = await supabase.auth.admin.createUser({
            id: existing.owner_id,
            email,
            password,
            email_confirm: true,
            user_metadata: { numeric_id, agency_id: agencyId },
          });
          if (!authUser) return res.json({ ok: false, error: 'Agency exists but auth user missing and could not be recreated' });
        }
      }
      return res.json({ ok: true, agency_id: agencyId, dashboard_email: email, dashboard_password: password, note: 'Agency already existed' });
    }

    const { data: userRow } = await supabase.from('users').select('auth_uid, name, numeric_id').eq('numeric_id', String(numeric_id)).maybeSingle();

    let ownerAuthId = null;

    // Always ensure auth user exists — even if userRow exists
    if (userRow) {
      ownerAuthId = userRow.auth_uid;
      const { data: existingAuth } = await supabase.auth.admin.getUserById(ownerAuthId);
      if (!existingAuth?.user) {
        const { data: authUser, error: authErr } = await supabase.auth.admin.createUser({
          id: ownerAuthId,
          email,
          password,
          email_confirm: true,
          user_metadata: { numeric_id, agency_id: agencyId },
        });
        if (authErr && !authErr.message?.includes('already')) {
          return res.json({ ok: false, error: 'Failed to recreate auth account: ' + authErr.message });
        }
        ownerAuthId = authUser?.id || ownerAuthId;
      }
    } else {
      try {
        const { data: authUser, error: authErr } = await supabase.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
          user_metadata: { numeric_id, agency_id: agencyId },
        });
        if (authErr && !authErr.message?.includes('already')) {
          return res.json({ ok: false, error: 'Failed to create auth account: ' + authErr.message });
        }
        ownerAuthId = authUser?.id || null;
      } catch (e) {
        return res.json({ ok: false, error: 'Auth creation failed: ' + e.message });
      }
    }

    const { error: agencyErr } = await supabase.from('agencies').insert({
      id: agencyId,
      name,
      owner_id: ownerAuthId,
      agency_type: type,
      description: `وكالة ${name}`,
      is_activated: true,
    });
    if (agencyErr) return res.json({ ok: false, error: 'Failed to create agency: ' + agencyErr.message });

    await supabase.from('agency_wallets').insert({
      agency_id: agencyId,
      diamonds_balance: 0,
      total_recharged: 0,
      total_withdrawn: 0,
    }).select();

    // Send DM notification to the user
    const typeLabel = type === 'hosting' ? 'استضافة' : type === 'mixed' ? 'مختلطة' : 'شحن ماس';
    try {
      const { data: targetUser } = await supabase.from('users').select('name').eq('numeric_id', String(numeric_id)).maybeSingle();
      await supabase.from('dm_messages').insert({
        from_user_id: 'system',
        to_user_id: String(numeric_id),
        from_name: 'النظام',
        to_name: targetUser?.name || String(numeric_id),
        text: `🎉 تم فتح وكالة "${name}" بنجاح (${typeLabel})! بيانات الدخول للوحة التحكم:\n\nالبريد: ${email}\nكلمة المرور: ${password}\n\nسجّل الدخول من لوحة تحكم الوكالة.`,
        is_read: false,
      });
    } catch (dmErr) {
      console.error('[OPEN-AGENCY] DM notification failed:', dmErr.message);
    }

    res.json({ ok: true, agency_id: agencyId, dashboard_email: email, dashboard_password: password });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// ---------- AGENCY OPEN REQUESTS (admin review) ----------

app.get('/api/admin/open-requests', async (req, res) => {
  try {
    if (!adminAuth(req, res)) return res.json({ ok: false, error: 'Forbidden' });
    await ensureOpenRequestsTable();
    const status = (req.query.status || 'pending').toString();
    const { data, error } = await supabase
      .from('agency_open_requests')
      .select('*')
      .eq('status', status)
      .order('created_at', { ascending: false });
    if (error) throw error;

    // Enrich with requester user info
    const enriched = await Promise.all((data || []).map(async (r) => {
      let requester = null;
      try {
        const { data: u } = await supabase.from('users').select('numeric_id, name, photo_url').eq('auth_uid', r.requested_by).maybeSingle();
        requester = u;
      } catch {}
      return { ...r, requester };
    }));
    res.json({ ok: true, requests: enriched });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.post('/api/admin/open-request/approve', async (req, res) => {
  try {
    if (!adminAuth(req, res)) return res.json({ ok: false, error: 'Forbidden' });
    await ensureOpenRequestsTable();
    const { request_id } = req.body;
    if (!request_id) return res.json({ ok: false, error: 'request_id required' });

    const { data: req, error: rErr } = await supabase
      .from('agency_open_requests')
      .select('*')
      .eq('id', request_id)
      .single();
    if (rErr || !req) return res.json({ ok: false, error: 'Request not found' });
    if (req.status !== 'pending') return res.json({ ok: false, error: 'Already processed' });

    const numeric_id = String(req.agency_id || '');
    const agencyId = `AG${numeric_id}`;
    const name = req.agency_name || `وكالة ${numeric_id}`;
    const ownerAuthId = req.requested_by;
    const type = req.agency_type || 'hosting';

    // 1. Create agency (idempotent)
    const { data: existing } = await supabase.from('agencies').select('id').eq('id', agencyId).maybeSingle();
    if (!existing) {
      const { data: userRow } = await supabase.from('users').select('auth_uid, name, numeric_id').eq('auth_uid', ownerAuthId).maybeSingle();
      const { error: agencyErr } = await supabase.from('agencies').insert({
        id: agencyId,
        name,
        owner_id: ownerAuthId,
        agency_type: type,
        description: `وكالة ${name}`,
        photo_url: req.photo_url || '',
        is_activated: true,
        personal_name: userRow?.name || '',
        national_id: req.id_card_url || '',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
      if (agencyErr) return res.json({ ok: false, error: 'فشل إنشاء الوكالة: ' + agencyErr.message });
    }

    // 2. Owner membership
    const { data: ownerMember } = await supabase
      .from('host_agency_members')
      .select('id')
      .eq('agency_id', agencyId)
      .eq('user_id', ownerAuthId)
      .maybeSingle();
    if (!ownerMember) {
      await supabase.from('host_agency_members').insert({
        agency_id: agencyId,
        user_id: ownerAuthId,
        role: 'owner',
        status: 'active',
        joined_at: new Date().toISOString(),
      });
    }

    // 3. Wallet
    const { data: wallet } = await supabase.from('agency_wallets').select('id').eq('agency_id', agencyId).maybeSingle();
    if (!wallet) {
      await supabase.from('agency_wallets').insert({
        agency_id: agencyId,
        diamonds_balance: 0,
        total_recharged: 0,
        total_withdrawn: 0,
      });
    }

    // 4. Mark request approved
    await supabase.from('agency_open_requests').update({
      status: 'approved',
      reviewed_by: 'admin',
      reviewed_at: new Date().toISOString(),
    }).eq('id', request_id);

    // 5. DM notification to the owner (to numeric_id)
    try {
      const { data: targetUser } = await supabase.from('users').select('name, numeric_id').eq('auth_uid', ownerAuthId).maybeSingle();
      const toNumeric = targetUser?.numeric_id || numeric_id;
      await supabase.from('dm_messages').insert({
        from_user_id: 'system',
        to_user_id: toNumeric,
        from_name: 'النظام',
        to_name: targetUser?.name || toNumeric,
        text: `🎉 تمت الموافقة على طلبك وفتح وكالة الاستضافة "${name}" بنجاح! يمكنك الآن دعوة أصدقائك للانضمام إليها وإدارة أعضائك من داخل التطبيق.`,
        is_read: false,
      });
    } catch (dmErr) { console.error('[APPROVE-OPEN-REQUEST] DM failed:', dmErr.message); }

    // 6. Realtime broadcast to surface an instant banner
    try {
      await supabase.from('app_broadcasts').insert({
        type: 'update',
        title: 'تم فتح وكالتك بنجاح 🎉',
        body: `أهلاً ${name}، تمت الموافقة على طلبك وفتح وكالة الاستضافة. يمكنك الآن دعوة الأعضاء وبدء الاستضافة.`,
        target: 'specific',
        is_active: true,
        payload: { agency_id: agencyId, to_user: ownerAuthId },
      });
    } catch (bcErr) { console.error('[APPROVE-OPEN-REQUEST] broadcast failed:', bcErr.message); }

    res.json({ ok: true, agency_id: agencyId });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

app.post('/api/admin/open-request/reject', async (req, res) => {
  try {
    if (!adminAuth(req, res)) return res.json({ ok: false, error: 'Forbidden' });
    await ensureOpenRequestsTable();
    const { request_id, note } = req.body;
    if (!request_id) return res.json({ ok: false, error: 'request_id required' });

    const { data: req, error: rErr } = await supabase.from('agency_open_requests').select('*').eq('id', request_id).single();
    if (rErr || !req) return res.json({ ok: false, error: 'Request not found' });
    if (req.status !== 'pending') return res.json({ ok: false, error: 'Already processed' });

    await supabase.from('agency_open_requests').update({
      status: 'rejected',
      note: note || '',
      reviewed_by: 'admin',
      reviewed_at: new Date().toISOString(),
    }).eq('id', request_id);

    try {
      const { data: targetUser } = await supabase.from('users').select('name, numeric_id').eq('auth_uid', req.requested_by).maybeSingle();
      const toNumeric = targetUser?.numeric_id || String(req.agency_id || '');
      await supabase.from('dm_messages').insert({
        from_user_id: 'system',
        to_user_id: toNumeric,
        from_name: 'النظام',
        to_name: targetUser?.name || toNumeric,
        text: `تم رفض طلب فتح وكالة "${req.agency_name}".${note ? `\nالسبب: ${note}` : ''}\nيمكنك التواصل مع الإدارة للمزيد.`,
        is_read: false,
      });
    } catch (dmErr) { console.error('[REJECT-OPEN-REQUEST] DM failed:', dmErr.message); }

    res.json({ ok: true });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// ---------- AGENCY REGISTER (new user creates account for existing agency) ----------
app.post('/api/admin/agency-register', async (req, res) => {
  try {
    const { agency_id, email, password } = req.body;
    if (!agency_id || !email || !password) return res.json({ ok: false, error: 'agency_id, email, password required' });

    const { data: agency } = await supabase.from('agencies').select('id, owner_id').eq('id', agency_id).maybeSingle();
    if (!agency) return res.json({ ok: false, error: 'الوكالة غير موجودة' });

    const { data: existingUser } = await supabase.auth.admin.listUsers();
    const alreadyExists = existingUser?.users?.find(u => u.email === email);
    if (alreadyExists) return res.json({ ok: false, error: 'البريد الإلكتروني مستخدم بالفعل' });

    const { data: authUser, error: authErr } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
    if (authErr) return res.json({ ok: false, error: 'فشل إنشاء الحساب: ' + authErr.message });

    await supabase.from('agencies').update({ owner_id: authUser.id }).eq('id', agency_id);

    await supabase.from('users').upsert({
      auth_uid: authUser.id,
      numeric_id: agency_id.replace('AG', ''),
      name: email.split('@')[0],
      email,
    }, { onConflict: 'auth_uid' });

    res.json({ ok: true, user_id: authUser.id });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// ---------- DASHBOARD STATS ----------
app.get('/api/dashboard/stats', async (req, res) => {
  try {
    const [users, rooms, messages, dms, participants, gifts] = await Promise.all([
      supabase.from('users').select('auth_uid,is_online', { count: 'exact' }),
      supabase.from('rooms').select('room_id,is_active', { count: 'exact' }),
      supabase.from('messages').select('id', { count: 'exact' }),
      supabase.from('dm_messages').select('id', { count: 'exact' }),
      supabase.from('participants').select('id', { count: 'exact' }),
      supabase.from('messages').select('gift_count').eq('type', 'gift'),
    ]);
    let diamondsSpent = 0;
    for (const r of gifts.data || []) diamondsSpent += Number(r.gift_count || 0);
    res.json({
      users: users.count || 0,
      rooms: rooms.count || 0,
      messages: messages.count || 0,
      dms: dms.count || 0,
      participants: participants.count || 0,
      giftsSent: gifts.data ? gifts.data.length : 0,
      diamondsSpent,
      onlineUsers: (users.data || []).filter((u) => u.is_online).length,
      activeRooms: (rooms.data || []).filter((r) => r.is_active).length,
    });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// ---------- UPLOAD AGENCY PHOTO (base64) ----------
app.post('/api/agency/upload-photo', authMiddleware(), async (req, res) => {
  try {
    const { agency_id, image_base64, filename } = req.body;
    if (!agency_id || !image_base64) return res.json({ ok: false, error: 'agency_id and image_base64 required' });

    const ext = filename?.split('.').pop() || 'png';
    const path = `agency-photos/${agency_id}.${ext}`;
    const buffer = Buffer.from(image_base64, 'base64');

    const { error } = await supabase.storage
      .from('agency-photos')
      .upload(path, buffer, { contentType: `image/${ext}`, upsert: true });
    if (error) return res.json({ ok: false, error: error.message });

    const { data: urlData } = supabase.storage
      .from('agency-photos')
      .getPublicUrl(path);

    res.json({ ok: true, url: urlData.publicUrl + '?t=' + Date.now() });
  } catch (e) { res.json({ ok: false, error: e.message }); }
});

// Generic fallback guard
app.use((req, res) => {
  res.json({ error: `Not found: ${req.method} ${req.path}` });
});

module.exports = app;
