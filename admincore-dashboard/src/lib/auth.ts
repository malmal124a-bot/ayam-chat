// Auth shim for the dashboard — sessionStorage-based admin login
// (no Firebase; the app itself uses Supabase).
export type AppUser = {
  id: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
};

const AUTH_KEY = 'ayam_admin_auth';

export function onAuthChange(callback: (user: AppUser | null) => void): () => void {
  const emit = () =>
    callback(sessionStorage.getItem(AUTH_KEY) === '1'
      ? { id: 'admin', email: 'admin@ayam', displayName: 'Admin', photoUrl: null }
      : null);
  emit();
  window.addEventListener('storage', emit);
  return () => window.removeEventListener('storage', emit);
}

export async function loginWithEmail(_email: string, _password: string) {
  throw new Error('Use the dashboard passcode to sign in.');
}

export async function logout() {
  sessionStorage.removeItem(AUTH_KEY);
}
