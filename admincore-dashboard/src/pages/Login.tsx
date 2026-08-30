import { useState } from 'react';
import { supabase, getAdminSupabase } from '../lib/supabase';
import { setAdminSession, type AppUser } from '../lib/auth';
import { getAdminUser, getAdminUserByEmail, repairAdminUid } from '../lib/db';

const ADMIN_PASS: string = import.meta.env.VITE_ADMIN_PASS || 'ayam-admin';

export default function Login({ onLogin }: { onLogin: () => void }) {
  const [email, setEmail] = useState('');
  const [pass, setPass] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async () => {
    setBusy(true);
    setError('');
    try {
      // 1) Master passcode (owner bootstrap) — full access, no DB row needed.
      if (pass === ADMIN_PASS) {
        const master: AppUser = {
          id: 'master',
          email: 'admin@ayam',
          displayName: 'المالك',
          photoUrl: null,
          role: 'superadmin',
          permissions: {},
        };
        setAdminSession(master);
        onLogin();
        return;
      }

      // 2) Real admin account (Supabase Auth + admin_users profile).
      const cleanEmail = email.trim();
      if (!cleanEmail || !cleanEmail.includes('@')) {
        setError('أدخل البريد الإلكتروني وكلمة المرور الخاصين بالمشرف');
        setBusy(false);
        return;
      }

      const { data: authData, error: authErr } = await supabase.auth.signInWithPassword({
        email: cleanEmail,
        password: pass,
      });
      if (authErr || !authData.user) {
        setError('بيانات الدخول غير صحيحة');
        setBusy(false);
        return;
      }

      const uid = authData.user.id;
      let profile = await getAdminUser(uid);
      if (!profile) {
        // Self-heal: older rows were created with a non-matching uid. Match by email.
        const byEmail = await getAdminUserByEmail(cleanEmail);
        if (byEmail) {
          await repairAdminUid(byEmail.uid, uid);
          profile = await getAdminUser(uid);
        }
      }
      if (!profile) {
        setError('هذا الحساب غير مسجل كمشرف في النظام');
        await supabase.auth.signOut().catch(() => {});
        setBusy(false);
        return;
      }
      if (profile.isActive === false) {
        setError('الحساب معطل، تواصل مع المالك');
        await supabase.auth.signOut().catch(() => {});
        setBusy(false);
        return;
      }

      const user: AppUser = {
        id: profile.uid,
        email: profile.email,
        displayName: profile.displayName,
        photoUrl: profile.photoUrl,
        role: profile.role,
        permissions: profile.permissions,
      };
      setAdminSession(user);
      onLogin();
    } catch (e: any) {
      setError(e?.message || 'حدث خطأ أثناء الدخول');
      setBusy(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 20,
      }}
    >
      <div className="card fade-in" style={{ width: '100%', maxWidth: 400, padding: 34 }}>
        <div style={{ textAlign: 'center', marginBottom: 26 }}>
          <div
            style={{
              width: 70,
              height: 70,
              borderRadius: 20,
              margin: '0 auto 14px',
              background: 'linear-gradient(135deg,var(--gold),var(--gold-2))',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 34,
              boxShadow: '0 12px 30px rgba(245,185,66,0.3)',
            }}
          >
            🐔
          </div>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 800 }}>لوحة تحكم Ayam Chat</h1>
          <p style={{ color: 'var(--muted)', margin: '6px 0 0', fontSize: 13 }}>
            إدارة المستخدمين والغرف والهدايا والمتجر مباشرة من قاعدة البيانات
          </p>
        </div>

        <label style={{ display: 'block', marginBottom: 14 }}>
          <div style={{ marginBottom: 6, color: 'var(--muted)', fontWeight: 700, fontSize: 12 }}>
            البريد الإلكتروني
          </div>
          <input
            className="input"
            type="email"
            value={email}
            autoFocus
            placeholder="admin@example.com"
            onChange={(e) => setEmail(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && submit()}
          />
        </label>

        <label style={{ display: 'block', marginBottom: 14 }}>
          <div style={{ marginBottom: 6, color: 'var(--muted)', fontWeight: 700, fontSize: 12 }}>
            كلمة المرور
          </div>
          <input
            className="input"
            type="password"
            value={pass}
            placeholder="••••••••"
            onChange={(e) => setPass(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && submit()}
          />
        </label>

        {error && (
          <div style={{ color: 'var(--red)', fontSize: 13, marginBottom: 12, fontWeight: 700 }}>✕ {error}</div>
        )}

        <button className="btn btn-gold" style={{ width: '100%', justifyContent: 'center' }} onClick={submit} disabled={busy}>
          {busy ? 'جاري التحقق...' : 'دخول'}
        </button>

        <p style={{ color: 'var(--muted)', fontSize: 11, textAlign: 'center', marginTop: 18, lineHeight: 1.8 }}>
          كلمة المرور الافتراضية للمالك: <b style={{ color: 'var(--gold)' }}>{ADMIN_PASS}</b>
          <br />
          يمكن تغييرها عبر متغير <code>VITE_ADMIN_PASS</code> — ولإنشاء مشرفين جدد ادخل من صفحة «إدارة المشرفين»
        </p>
      </div>
    </div>
  );
}
