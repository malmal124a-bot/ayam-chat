// Auth helpers for the dashboard — sessionStorage-based admin login.
// A "session" is the admin profile loaded after authenticating: it carries the
// role + permissions used to restrict which pages/sections are visible.
export type AppUser = {
  id: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  role?: string | null; // 'superadmin' | 'admin' | 'moderator' | 'owner'
  permissions?: Record<string, boolean> | null;
};

const AUTH_KEY = 'ayam_admin_auth';

/** Master fallback (VITE_ADMIN_PASS) — full access, no DB row. */
const MASTER: AppUser = {
  id: 'master',
  email: 'admin@ayam',
  displayName: 'المالك',
  photoUrl: null,
  role: 'superadmin',
  permissions: {},
};

export function getAdminSession(): AppUser | null {
  try {
    const raw = sessionStorage.getItem(AUTH_KEY);
    if (!raw) return null;
    if (raw === '1') return MASTER; // legacy shared-passcode login
    const parsed = JSON.parse(raw) as AppUser;
    if (!parsed || typeof parsed !== 'object') return MASTER;
    return parsed;
  } catch {
    return null;
  }
}

export function setAdminSession(user: AppUser) {
  sessionStorage.setItem(AUTH_KEY, JSON.stringify(user));
}

export function isSuper(user: AppUser | null): boolean {
  return user?.role === 'superadmin' || user?.role === 'owner';
}

export function onAuthChange(callback: (user: AppUser | null) => void): () => void {
  const emit = () => callback(getAdminSession());
  emit();
  window.addEventListener('storage', emit);
  return () => window.removeEventListener('storage', emit);
}

export async function loginWithEmail(_email: string, _password: string) {
  throw new Error('Use the dashboard login form to sign in.');
}

export async function logout() {
  sessionStorage.removeItem(AUTH_KEY);
}
