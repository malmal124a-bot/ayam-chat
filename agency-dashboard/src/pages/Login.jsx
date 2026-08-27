import { useState, useEffect, useRef } from 'react';
import { loginAgency, registerAgency } from '../lib/api';

function getUrlParams() {
  const hash = window.location.hash.slice(1);
  if (!hash) return {};
  const params = new URLSearchParams(hash);
  return {
    agency_id: params.get('agency_id') || '',
    email: params.get('email') || '',
    password: params.get('password') || '',
  };
}

export default function Login({ onLogin }) {
  const urlParams = getUrlParams();
  const [email, setEmail] = useState(urlParams.email || '');
  const [password, setPassword] = useState(urlParams.password || '');
  const [agencyId, setAgencyId] = useState(urlParams.agency_id || '');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [mode, setMode] = useState('login');
  const didAutoLogin = useRef(false);

  const doLogin = async (e) => {
    if (e?.preventDefault) e.preventDefault();
    const loginEmail = email || urlParams.email;
    const loginPassword = password || urlParams.password;
    const loginAgencyId = agencyId || urlParams.agency_id;
    if (!loginEmail || !loginPassword || !loginAgencyId) {
      setError('جميع الحقول مطلوبة');
      return;
    }
    setLoading(true);
    setError('');
    try {
      if (mode === 'register') {
        await registerAgency(loginAgencyId.trim(), loginEmail, loginPassword);
      } else {
        await loginAgency(loginEmail, loginPassword);
      }
      const raw = localStorage.getItem('agency_session');
      if (raw) {
        const s = JSON.parse(raw);
        s.agency_id = loginAgencyId.trim();
        localStorage.setItem('agency_session', JSON.stringify(s));
      }
      onLogin();
    } catch (err) {
      setError(err.message || (mode === 'register' ? 'فشل إنشاء الحساب' : 'فشل تسجيل الدخول'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!didAutoLogin.current && urlParams.email && urlParams.password && urlParams.agency_id) {
      didAutoLogin.current = true;
      setTimeout(() => doLogin(), 100);
    }
  }, []);

  return (
    <div className="login-page">
      <div className="login-card">
        <h1>🏢 لوحة تحكم الوكالة</h1>
        <p className="subtitle">
          {mode === 'register' ? 'أنشئ حساب جديد للتحكم في وكالتك' : 'سجّل الدخول للتحكم في وكالتك'}
        </p>

        {error && (
          <div style={{ padding: '10px 14px', background: 'rgba(231,76,60,0.15)', color: '#e74c3c', borderRadius: 8, marginBottom: 16, fontSize: 13 }}>
            {error}
          </div>
        )}

        <form onSubmit={doLogin}>
          <div className="form-group">
            <label>رقم الوكالة</label>
            <input
              type="text"
              value={agencyId}
              onChange={(e) => setAgencyId(e.target.value)}
              placeholder="مثال: AG123456"
              dir="ltr"
              style={{ textAlign: 'center', fontSize: 18, letterSpacing: 2 }}
            />
          </div>
          <div className="form-group">
            <label>البريد الإلكتروني</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="agent@ayam.chat"
              dir="ltr"
            />
          </div>
          <div className="form-group">
            <label>كلمة المرور</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              dir="ltr"
            />
          </div>
          <button type="submit" className="btn btn-gold" disabled={loading}>
            {loading
              ? (mode === 'register' ? 'جاري الإنشاء...' : 'جاري الدخول...')
              : (mode === 'register' ? 'إنشاء حساب جديد' : 'تسجيل الدخول')
            }
          </button>
        </form>

        <div style={{ textAlign: 'center', marginTop: 16 }}>
          <button
            type="button"
            onClick={() => { setMode(mode === 'login' ? 'register' : 'login'); setError(''); }}
            style={{
              background: 'none', border: 'none', color: 'var(--gold)', cursor: 'pointer',
              fontSize: 14, textDecoration: 'underline', padding: '4px 8px',
            }}
          >
            {mode === 'login' ? 'ليس لديك حساب؟ أنشئ حساب جديد' : 'لديك حساب بالفعل؟ سجّل الدخول'}
          </button>
        </div>
      </div>
    </div>
  );
}
