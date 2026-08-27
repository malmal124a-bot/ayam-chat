require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const { authMiddleware } = require('./auth');
const createAgencyRoutes = require('./routes/agency');

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

const log = (msg) => console.log(`[${new Date().toISOString()}] ${msg}`);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', supabase: supabase ? 'connected' : 'missing_config' });
});

app.get('/', (_req, res) => {
  res.json({
    name: 'Ayam Chat API',
    endpoints: [
      '/health', '/api/users', '/api/agencies', '/api/medals', '/api/rooms',
      '/api/store_items', '/api/banners', '/api/dm_messages', '/api/dashboard/stats',
      '/api/agency/* (auth required)',
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
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.get('/api/users/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users').select('*')
      .or(`auth_uid.eq.${req.params.id},numeric_id.eq.${req.params.id}`)
      .maybeSingle();
    if (error) throw error;
    if (!data) return res.status(404).json({ error: 'User not found' });
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/users', async (req, res) => {
  try {
    const { data, error } = await supabase.from('users').insert(req.body).select().single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.patch('/api/users/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users').update(req.body)
      .or(`auth_uid.eq.${req.params.id},numeric_id.eq.${req.params.id}`)
      .select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ---------- AGENCIES ----------
app.get('/api/agencies', async (req, res) => {
  try {
    const { data, error } = await supabase.from('agencies').select('*');
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.get('/api/agencies/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('agencies').select('*').eq('id', req.params.id).maybeSingle();
    if (error) throw error;
    if (!data) return res.status(404).json({ error: 'Agency not found' });
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/agencies', async (req, res) => {
  try {
    const { data, error } = await supabase.from('agencies').insert(req.body).select().single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.patch('/api/agencies/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('agencies').update(req.body).eq('id', req.params.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ---------- MEDALS ----------
app.get('/api/medals', async (req, res) => {
  try {
    const { data, error } = await supabase.from('medals').select('*').order('order');
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ---------- ROOMS ----------
app.get('/api/rooms', async (req, res) => {
  try {
    const { data, error } = await supabase.from('rooms').select('*');
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.get('/api/rooms/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('rooms').select('*').eq('room_id', req.params.id).maybeSingle();
    if (error) throw error;
    if (!data) return res.status(404).json({ error: 'Room not found' });
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.patch('/api/rooms/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('rooms').update(req.body).eq('room_id', req.params.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ---------- STORE ITEMS (gifts / frames / entry effects / fancy ids) ----------
// This is the catalog the app reads (lib/services/catalog_service.dart) and the
// admin dashboard (admincore-dashboard) manages with Cloudinary uploads.
app.get('/api/store_items', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('store_items').select('*').order('order');
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/store_items', async (req, res) => {
  try {
    const item = { ...req.body, updated_at: new Date().toISOString() };
    if (!item.id) { item.id = `item_${Date.now()}`; item.created_at = new Date().toISOString(); }
    const { data, error } = await supabase
      .from('store_items').upsert(item, { onConflict: 'id' }).select().single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.patch('/api/store_items/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('store_items').update({ ...req.body, updated_at: new Date().toISOString() })
      .eq('id', req.params.id).select().single();
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.delete('/api/store_items/:id', async (req, res) => {
  try {
    const { error } = await supabase.from('store_items').delete().eq('id', req.params.id);
    if (error) throw error;
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ---------- BANNERS ----------
app.get('/api/banners', async (req, res) => {
  try {
    const { data, error } = await supabase.from('banners').select('*').order('order');
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/api/banners', async (req, res) => {
  try {
    const banner = req.body;
    if (!banner.id) banner.id = crypto.randomUUID();
    const { data, error } = await supabase
      .from('banners').upsert(banner, { onConflict: 'id' }).select().single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.delete('/api/banners/:id', async (req, res) => {
  try {
    const { error } = await supabase.from('banners').delete().eq('id', req.params.id);
    if (error) throw error;
    res.json({ ok: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ---------- DIRECT MESSAGES ----------
app.get('/api/dm_messages', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('dm_messages').select('*').order('created_at', { ascending: false }).limit(500);
    if (error) throw error;
    res.json(data);
  } catch (e) { res.status(500).json({ error: e.message }); }
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
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Generic fallback guard
app.use((req, res) => {
  res.status(404).json({ error: `Not found: ${req.method} ${req.path}` });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  log(`Ayam Chat API running on port ${PORT}`);
  log(`Supabase: ${supabase ? 'connected' : 'NOT CONFIGURED - set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY'}`);
});
