import { useState } from 'react';

const ADMIN_PASS: string = import.meta.env.VITE_ADMIN_PASS || 'ayam-admin';

export default function Login({ onLogin }: { onLogin: () => void }) {
  const [pass, setPass] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = () => {
    setBusy(true);
    setError('');
    setTimeout(() => {
      if (pass === ADMIN_PASS) {
        sessionStorage.setItem('ayam_admin_auth', '1');
        onLogin();
      } else {
        setError('كلمة المرور غير صحيحة');
        setBusy(false);
      }
    }, 300);
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
            كلمة مرور المسؤول
          </div>
          <input
            className="input"
            type="password"
            value={pass}
            autoFocus
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
          كلمة المرور الافتراضية: <b style={{ color: 'var(--gold)' }}>ayam-admin</b>
          <br />
          يمكن تغييرها عبر متغير <code>VITE_ADMIN_PASS</code>
        </p>
      </div>
    </div>
  );
}
