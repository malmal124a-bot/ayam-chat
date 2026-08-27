import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://dhabrfnfirhhcrdbvzdi.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRoYWJyZm5maXJoaGNyZGJ2emRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2NDU1MjcsImV4cCI6MjEwMjIyMTUyN30.Mjv1YJh2TM9js8qXmlru0Jzbqoi9GJ1qzx-GQ2o3GeM';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// API base URL — backend server (Railway)
const API_BASE = import.meta.env.VITE_API_URL || 'https://backend-seven-brown-72.vercel.app';

/**
 * Make an authenticated API call to the backend
 */
export async function api(path, options = {}) {
  const sessionRaw = localStorage.getItem('agency_session');
  if (!sessionRaw) throw new Error('Not logged in');
  const session = JSON.parse(sessionRaw);
  if (!session.agency_id && session.user?.email) {
    session.agency_id = 'AG' + session.user.email.split('@')[0];
  }

  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${session.access_token}`,
      ...(options.headers || {}),
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  const data = await res.json();
  if (data.ok === false) throw new Error(data.error || 'API error');
  return data;
}

/**
 * GET helper
 */
export async function apiGet(path) {
  return api(path, { method: 'GET' });
}

/**
 * POST helper
 */
export async function apiPost(path, body) {
  return api(path, { method: 'POST', body });
}

/**
 * Login via Supabase email/password
 */
export async function loginAgency(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;

  // Save session
  localStorage.setItem('agency_session', JSON.stringify({
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    user: data.user,
  }));

  return data.user;
}

/**
 * Register new agency user + link to agency
 */
export async function registerAgency(agencyId, email, password) {
  const data = await apiPost('/api/admin/agency-register', { agency_id: agencyId, email, password });

  // Now login
  const loginData = await supabase.auth.signInWithPassword({ email, password });
  if (loginData.error) throw loginData.error;

  localStorage.setItem('agency_session', JSON.stringify({
    access_token: loginData.data.session.access_token,
    refresh_token: loginData.data.session.refresh_token,
    user: loginData.data.user,
  }));

  return loginData.data.user;
}

/**
 * Logout
 */
export function logoutAgency() {
  localStorage.removeItem('agency_session');
  supabase.auth.signOut();
}

/**
 * Get current session
 */
export function getSession() {
  const raw = localStorage.getItem('agency_session');
  if (!raw) return null;
  try {
    const s = JSON.parse(raw);
    if (!s.user) return null;
    if (!s.agency_id && s.user?.email) {
      s.agency_id = 'AG' + s.user.email.split('@')[0];
      localStorage.setItem('agency_session', JSON.stringify(s));
    }
    return s;
  } catch { return null; }
}

/**
 * Refresh session if needed
 */
export async function refreshSession() {
  const raw = localStorage.getItem('agency_session');
  if (!raw) return null;
  try {
    const s = JSON.parse(raw);
    if (!s.refresh_token) return s;
    const { data, error } = await supabase.auth.refreshSession({ refresh_token: s.refresh_token });
    if (error || !data.session) return null;
    const updated = {
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      user: data.user,
      agency_id: s.agency_id,
    };
    localStorage.setItem('agency_session', JSON.stringify(updated));
    return updated;
  } catch { return null; }
}
