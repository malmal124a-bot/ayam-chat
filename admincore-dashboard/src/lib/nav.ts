// Central navigation + permission definitions for the admin dashboard.
// The permission key for each page === its nav `key`, so the owner can grant
// or deny access to every individual page from AdminManagement.

export type NavItem = { key: string; label: string; icon: string };
export type NavGroup = { title?: string; items: NavItem[] };

export const NAV_GROUPS: NavGroup[] = [
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

export const NAV_ITEMS = NAV_GROUPS.flatMap((g) => g.items);

export const PAGE_TITLES: Record<string, string> = Object.fromEntries(
  NAV_ITEMS.map((n) => [n.key, n.label]),
);

// A super/owner account can see everything. Everyone else is restricted to the
// pages explicitly granted in their `permissions` map.
export function isSuper(role?: string | null): boolean {
  return role === 'superadmin' || role === 'owner';
}

// Pages every authenticated admin can always reach (safe landing screens).
const ALWAYS_VISIBLE = new Set(['overview', 'dashboard']);

export function canAccess(
  permissions: Record<string, boolean> | null | undefined,
  pageKey: string,
  role?: string | null,
): boolean {
  if (isSuper(role)) return true;
  if (ALWAYS_VISIBLE.has(pageKey)) return true;
  if (!permissions) return false;
  return !!permissions[pageKey];
}

// First page the current user is allowed to see (used as the landing page).
export function firstAllowedPage(
  permissions: Record<string, boolean> | null | undefined,
  role?: string | null,
): string {
  const fallback = 'overview';
  for (const item of NAV_ITEMS) {
    if (canAccess(permissions, item.key, role)) return item.key;
  }
  return fallback;
}
