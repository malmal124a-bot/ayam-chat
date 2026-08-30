import { useState, type ReactNode } from 'react';
import { NAV_GROUPS, PAGE_TITLES, canAccess } from '../lib/nav';
import type { AppUser } from '../lib/auth';

const SIDEBAR_W = 230;

export default function Layout({
  page,
  onNavigate,
  onLogout,
  children,
  currentUser,
}: {
  page: string;
  onNavigate: (p: string) => void;
  onLogout: () => void;
  children: ReactNode;
  currentUser: AppUser | null;
}) {
  const [collapsed, setCollapsed] = useState(false);

  // Only show nav items the current admin is allowed to access.
  const visibleGroups = NAV_GROUPS.map((g) => ({
    ...g,
    items: g.items.filter((it) =>
      canAccess(currentUser?.permissions, it.key, currentUser?.role),
    ),
  })).filter((g) => g.items.length > 0);

  return (
    <div style={{ minHeight: '100vh', display: 'flex', background: 'var(--bg)', color: '#cbd5e1' }}>
      {/* Sidebar */}
      <aside
        style={{
          width: collapsed ? 72 : SIDEBAR_W,
          flexShrink: 0,
          background: 'var(--panel)',
          borderLeft: '1px solid var(--border)',
          display: 'flex',
          flexDirection: 'column',
          transition: 'width 0.18s',
          position: 'sticky',
          top: 0,
          height: '100vh',
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            padding: '16px 14px',
            borderBottom: '1px solid var(--border)',
          }}
        >
          <span style={{ fontSize: 26 }}>🐔</span>
          {!collapsed && (
            <div>
              <div style={{ fontWeight: 900, fontSize: 15, color: '#fff', whiteSpace: 'nowrap' }}>
                Ayam Chat
              </div>
              <div style={{ fontSize: 11, color: 'var(--muted)', whiteSpace: 'nowrap' }}>
                لوحة التحكم
              </div>
            </div>
          )}
        </div>

        <nav style={{ flex: 1, overflowY: 'auto', padding: '10px 8px' }}>
          {visibleGroups.map((group, gi) => (
            <div key={gi} style={{ marginBottom: 10 }}>
              {!collapsed && group.title && (
                <div
                  style={{
                    fontSize: 10.5,
                    fontWeight: 800,
                    color: 'var(--muted)',
                    padding: '8px 12px 4px',
                    textTransform: 'uppercase',
                    letterSpacing: 0.5,
                  }}
                >
                  {group.title}
                </div>
              )}
              {group.items.map((item) => {
                const active = page === item.key;
                return (
                  <button
                    key={item.key}
                    onClick={() => onNavigate(item.key)}
                    title={item.label}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 10,
                      width: '100%',
                      padding: '9px 12px',
                      marginBottom: 2,
                      borderRadius: 10,
                      border: 'none',
                      cursor: 'pointer',
                      background: active ? 'linear-gradient(135deg,var(--gold),var(--gold-2))' : 'transparent',
                      color: active ? '#1a1a1a' : 'var(--muted)',
                      fontWeight: active ? 800 : 600,
                      fontSize: 13.5,
                      whiteSpace: 'nowrap',
                    }}
                  >
                    <span style={{ fontSize: 17 }}>{item.icon}</span>
                    {!collapsed && <span>{item.label}</span>}
                  </button>
                );
              })}
            </div>
          ))}
        </nav>

        <div style={{ padding: '10px 8px', borderTop: '1px solid var(--border)' }}>
          <button
            onClick={() => setCollapsed((c) => !c)}
            style={{
              width: '100%',
              padding: '8px 12px',
              marginBottom: 6,
              borderRadius: 10,
              border: '1px solid var(--border)',
              background: 'transparent',
              color: 'var(--muted)',
              cursor: 'pointer',
              fontSize: 12.5,
            }}
          >
            {collapsed ? '⬅' : 'طي القائمة'}
          </button>
          <button
            onClick={onLogout}
            style={{
              width: '100%',
              padding: '8px 12px',
              borderRadius: 10,
              border: '1px solid rgba(239,83,80,0.4)',
              background: 'rgba(239,83,80,0.12)',
              color: '#f87171',
              cursor: 'pointer',
              fontSize: 13,
              fontWeight: 700,
            }}
          >
            {collapsed ? '⎋' : 'تسجيل الخروج'}
          </button>
        </div>
      </aside>

      {/* Main column */}
      <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column' }}>
        <header
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: 12,
            padding: '14px 20px',
            background: 'var(--panel)',
            borderBottom: '1px solid var(--border)',
            position: 'sticky',
            top: 0,
            zIndex: 10,
          }}
        >
          <h1 style={{ margin: 0, fontSize: 17, fontWeight: 800, color: 'var(--gold)' }}>
            {PAGE_TITLES[page] ?? 'لوحة التحكم'}
          </h1>
          <span style={{ fontSize: 12, color: 'var(--muted)', display: 'flex', alignItems: 'center', gap: 8 }}>
            {currentUser?.displayName ? (
              <span style={{
                background: 'var(--gold)',
                color: '#1a1a1a',
                fontWeight: 800,
                padding: '2px 9px',
                borderRadius: 20,
                fontSize: 11,
              }}>
                {currentUser.displayName}
              </span>
            ) : null}
            {currentUser?.role ? <span>{currentUser.role}</span> : null}
          </span>
        </header>

        <main style={{ flex: 1, overflowY: 'auto', padding: 20 }}>{children}</main>
      </div>
    </div>
  );
}
