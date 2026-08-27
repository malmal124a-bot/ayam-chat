import { useState, type ReactNode } from 'react';

const NAV_GROUPS: { title?: string; items: { key: string; label: string; icon: string }[] }[] = [
  {
    items: [
      { key: 'overview', label: 'نظرة عامة', icon: '📊' },
      { key: 'dashboard', label: 'الإحصائيات', icon: '📈' },
      { key: 'users', label: 'المستخدمون', icon: '👥' },
      { key: 'rooms', label: 'الغرف', icon: '🏠' },
      { key: 'messages', label: 'رسائل الغرف', icon: '💬' },
      { key: 'dms', label: 'الرسائل الخاصة', icon: '✉️' },
    ],
  },
  {
    title: 'المتجر والهدايا',
    items: [
      { key: 'store', label: 'المتجر / الهدايا', icon: '🛍️' },
      { key: 'gifts', label: 'الهدايا', icon: '🎁' },
      { key: 'giftCategories', label: 'تصنيفات الهدايا', icon: '📁' },
      { key: 'giftItems', label: 'الهدايا المرسلة', icon: '🎀' },
      { key: 'giftBoxCustomize', label: 'صندوق الهدايا', icon: '📦' },
      { key: 'giftBannerConfigs', label: 'لافتات الهدايا', icon: '🖼️' },
      { key: 'svgaOverrides', label: 'روابط SVGA', icon: '🎬' },
      { key: 'banners', label: 'البنرات', icon: '🚩' },
    ],
  },
  {
    title: 'الشارات والمستويات',
    items: [
      { key: 'badges', label: 'الشارات', icon: '🏅' },
      { key: 'necklaces', label: 'القلائد', icon: '📿' },
      { key: 'badgeNecklaceGifts', label: 'إهداء شارات/قلائد', icon: '💝' },
      { key: 'levels', label: 'المستويات', icon: '⬆️' },
    ],
  },
  {
    title: 'VIP و CP',
    items: [
      { key: 'vip', label: 'VIP', icon: '👑' },
      { key: 'vipGifting', label: 'إهداء VIP', icon: '💎' },
      { key: 'cp', label: 'CP', icon: '💑' },
      { key: 'cpFeatures', label: 'ميزات CP', icon: '⚙️' },
      { key: 'cpVisualManager', label: 'مظهر CP', icon: '🎨' },
      { key: 'unions', label: 'العائلات', icon: '🤝' },
      { key: 'agency', label: 'الوكالات', icon: '🏢' },
    ],
  },
  {
    title: 'تخصيص التطبيق',
    items: [
      { key: 'appAssets', label: 'أصول التطبيق', icon: '🗂️' },
      { key: 'appIcons', label: 'أيقونات التطبيق', icon: '🔲' },
      { key: 'imageCustomize', label: 'تخصيص الصور', icon: '🖼️' },
      { key: 'colorCustomize', label: 'تخصيص الألوان', icon: '🎨' },
      { key: 'screenCustomization', label: 'تخصيص الشاشات', icon: '📱' },
      { key: 'visualManager', label: 'مدير المظهر', icon: '✨' },
      { key: 'profileCustomize', label: 'تخصيص الملف', icon: '👤' },
    ],
  },
  {
    title: 'النظام',
    items: [
      { key: 'signinFeatures', label: 'مكافآت تسجيل الدخول', icon: '📅' },
      { key: 'notifications', label: 'الإشعارات', icon: '🔔' },
      { key: 'adminManagement', label: 'إدارة المشرفين', icon: '🔐' },
      { key: 'bd', label: 'شركاء BD', icon: '🤝' },
      { key: 'errorAnalysis', label: 'تحليل الأخطاء', icon: '🐞' },
      { key: 'settings', label: 'الإعدادات', icon: '⚙️' },
    ],
  },
];

const NAV_ITEMS = NAV_GROUPS.flatMap((g) => g.items);

const PAGE_TITLES: Record<string, string> = Object.fromEntries(
  NAV_ITEMS.map((n) => [n.key, n.label]),
);

const SIDEBAR_W = 230;

export default function Layout({
  page,
  onNavigate,
  onLogout,
  children,
}: {
  page: string;
  onNavigate: (p: string) => void;
  onLogout: () => void;
  children: ReactNode;
}) {
  const [collapsed, setCollapsed] = useState(false);

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
          {NAV_GROUPS.map((group, gi) => (
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
          <span style={{ fontSize: 12, color: 'var(--muted)' }}>
            نفس قاعدة بيانات التطبيق — Supabase مباشرة
          </span>
        </header>

        <main style={{ flex: 1, overflowY: 'auto', padding: 20 }}>{children}</main>
      </div>
    </div>
  );
}
