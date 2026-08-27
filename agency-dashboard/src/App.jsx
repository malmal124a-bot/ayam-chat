import { useState, useEffect } from 'react';
import { getSession, logoutAgency, refreshSession, api } from './lib/api';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Recharge from './pages/Recharge';
import Members from './pages/Members';
import Logs from './pages/Logs';
import TopupWallet from './pages/TopupWallet';

const ALL_NAV = [
  { key: 'dashboard', label: 'الرئيسية', icon: '📊' },
  { key: 'topup', label: 'شحن رصيد الوكالة', icon: '💰', shippingOnly: true },
  { key: 'recharge', label: 'شحن و سحب', icon: '💎', shippingOnly: true },
  { key: 'members', label: 'الأعضاء والرواتب', icon: '👥' },
  { key: 'logs', label: 'السجلات', icon: '📋' },
];

function ensureAgencyId(s) {
  if (s && !s.agency_id && s.user?.email) {
    s.agency_id = 'AG' + s.user.email.split('@')[0];
  }
  return s;
}

export default function App() {
  const [session, setSession] = useState(() => ensureAgencyId(getSession()));
  const [page, setPage] = useState('dashboard');
  const [toast, setToast] = useState(null);
  const [agencyType, setAgencyType] = useState(null);

  useEffect(() => {
    if (session?.agency_id) {
      api(`/api/agency/profile?agency_id=${session.agency_id}`).then(data => {
        if (data?.agency_type) setAgencyType(data.agency_type);
      }).catch(() => {});
    }
  }, [session?.agency_id]);

  const NAV = ALL_NAV.filter(n => !n.shippingOnly || agencyType === 'shipping' || agencyType === 'mixed');

  // Auto-refresh session every 30 min
  useEffect(() => {
    const iv = setInterval(async () => {
      const s = await refreshSession();
      if (s) setSession(s);
      else setSession(null);
    }, 30 * 60 * 1000);
    return () => clearInterval(iv);
  }, []);

  if (!session) {
    return <Login onLogin={(u) => { setSession(getSession()); }} />;
  }

  const showToast = (msg, type = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  return (
    <div className="app-container">
      {toast && <div className={`toast toast-${toast.type}`}>{toast.msg}</div>}

      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-logo">
          <h2>🏢 لوحة الوكالة</h2>
          <p>{session.user?.email}</p>
        </div>
        <nav>
          {NAV.map((n) => (
            <a
              key={n.key}
              href="#"
              className={page === n.key ? 'active' : ''}
              onClick={(e) => { e.preventDefault(); setPage(n.key); }}
            >
              <span>{n.icon}</span>
              <span>{n.label}</span>
            </a>
          ))}
        </nav>
        <div className="sidebar-footer">
          <button onClick={() => { logoutAgency(); setSession(null); }}>
            خروج
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        {page === 'dashboard' && <Dashboard session={session} toast={showToast} />}
        {page === 'topup' && (agencyType === 'shipping' || agencyType === 'mixed') && <TopupWallet session={session} toast={showToast} />}
        {page === 'recharge' && (agencyType === 'shipping' || agencyType === 'mixed') && <Recharge session={session} toast={showToast} />}
        {page === 'members' && <Members session={session} toast={showToast} />}
        {page === 'logs' && <Logs session={session} toast={showToast} />}
      </main>
    </div>
  );
}
