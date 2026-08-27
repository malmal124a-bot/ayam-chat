// ============================================================
// Real Supabase client — SAME project & keys as the Flutter app
// (lib/services/supabase_service.dart) so the dashboard reads/writes
// the exact same database the app uses.
// ============================================================
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

export const SUPABASE_URL: string =
  import.meta.env.VITE_SUPABASE_URL || 'https://dhabrfnfirhhcrdbvzdi.supabase.co';

export const SUPABASE_ANON_KEY: string =
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRoYWJyZm5maXJoaGNyZGJ2emRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2NDU1MjcsImV4cCI6MjEwMjIyMTUyN30.Mjv1YJh2TM9js8qXmlru0Jzbqoi9GJ1qzx-GQ2o3GeM';

export const supabase: SupabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Service-role client (RLS bypass + auth.admin) — reads the key saved from the
// Settings page (localStorage "supabase_admin_config"). Falls back to anon.
let adminClient: SupabaseClient | null = null;
export function getAdminSupabase(): SupabaseClient {
  try {
    const raw = localStorage.getItem('supabase_admin_config');
    if (raw) {
      const cfg = JSON.parse(raw);
      const key = (cfg.serviceRoleKey || '').trim();
      if (key && cfg.supabaseUrl) {
        if (!adminClient) {
          adminClient = createClient(String(cfg.supabaseUrl), key, {
            auth: { autoRefreshToken: false, persistSession: false },
          });
        }
        return adminClient;
      }
    }
  } catch {
    /* ignore */
  }
  return supabase;
}

export function isAdminConnected(): boolean {
  try {
    const raw = localStorage.getItem('supabase_admin_config');
    if (!raw) return false;
    const cfg = JSON.parse(raw);
    return !!(cfg.serviceRoleKey && cfg.supabaseUrl);
  } catch {
    return false;
  }
}

export function resetAdminClient() {
  adminClient = null;
}
