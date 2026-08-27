import { NavLink, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Users, Gift, Store, DoorOpen,
  Building2, Crown, BarChart3, Award, Handshake,
  TrendingUp, Image, Palette, Bug,
  Bell, Settings, Shield, ChevronLeft, LogOut,   SlidersHorizontal, Grid, Gift as GiftIcon,
  Tag, Sparkles, Eye, ImageIcon, Calendar,
} from 'lucide-react';
import { logout } from '../lib/auth';
import { useContext } from 'react';
import { I18nContext } from '../lib/i18n';

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'nav.dashboard', end: true },
  { to: '/users', icon: Users, label: 'nav.users' },
  { to: '/gifts', icon: Gift, label: 'nav.gifts' },
  { to: '/store', icon: Store, label: 'nav.store' },
  { to: '/rooms', icon: DoorOpen, label: 'nav.rooms' },
  { to: '/unions', icon: Building2, label: 'nav.unions' },
  { to: '/vip', icon: Crown, label: 'nav.vip' },
  { to: '/vip-gifting', icon: GiftIcon, label: 'nav.vipGifting' },
  { to: '/levels', icon: BarChart3, label: 'nav.levels' },
  { to: '/badges', icon: Award, label: 'nav.badges' },
  { to: '/necklaces', icon: Crown, label: 'nav.necklaces' },
  { to: '/badge-necklace-gifts', icon: GiftIcon, label: 'Badge & Necklace Gifts' },
  { to: '/screen-customization', icon: LayoutDashboard, label: 'nav.screenVisuals' },
  { to: '/app-icons', icon: ImageIcon, label: 'nav.appIcons' },
  { to: '/gift-items', icon: Gift, label: 'nav.giftItems' },
  { to: '/gift-categories', icon: Tag, label: 'nav.giftCategories' },
  { to: '/gift-banner-configs', icon: Sparkles, label: 'nav.giftBannerConfigs' },
  { to: '/banners', icon: SlidersHorizontal, label: 'nav.banners' },
  { to: '/agency', icon: Handshake, label: 'nav.agency' },
  { to: '/cp-features', icon: Gift, label: 'CP Features' },
  { to: '/signin-features', icon: Calendar, label: 'nav.signin' },
  { to: '/bd', icon: TrendingUp, label: 'nav.bd' },
  { to: '/visual-manager', icon: Eye, label: 'Visual Manager' },
  { to: '/app-assets', icon: Grid, label: 'nav.appAssets' },
  { to: '/image-customize', icon: Image, label: 'nav.images' },
  { to: '/color-customize', icon: Palette, label: 'nav.colors' },
  { to: '/profile-customize', icon: Shield, label: 'Profile Customize' },
  { to: '/error-analysis', icon: Bug, label: 'nav.errors' },
  { to: '/admins', icon: Shield, label: 'nav.admins' },
  { to: '/notifications', icon: Bell, label: 'nav.notifications' },
  { to: '/settings', icon: Settings, label: 'nav.settings' },
];

export default function Sidebar({ collapsed, onToggle, mobileOpen, onMobileClose }: { collapsed: boolean; onToggle: () => void; mobileOpen?: boolean; onMobileClose?: () => void }) {
  const location = useLocation();
  const { t, lang } = useContext(I18nContext);

  return (
    <>
    {/* Mobile overlay sidebar */}
    <aside className={`fixed inset-y-0 z-20 lg:hidden transition-transform duration-300 bg-[#0D0D0E] flex flex-col ${lang === 'ar' ? 'left-0 border-l border-white/5' : 'right-0 border-r border-white/5'} ${mobileOpen ? 'translate-x-0' : lang === 'ar' ? 'translate-x-full' : '-translate-x-full'}`} style={{ width: '16rem' }}>
      <div className="p-4 flex items-center justify-between border-b border-white/5 h-14">
        <div className={`flex items-center gap-2 ${lang === 'ar' ? 'flex-row-reverse' : ''}`}>
          <div className="w-7 h-7 rounded bg-indigo-600 flex items-center justify-center text-white font-bold text-xs">Z</div>
          <span className="text-white font-semibold text-sm" style={{ fontFamily: lang === 'ar' ? 'system-ui' : 'inherit' }}>{t('app.name')}</span>
        </div>
        <button onClick={onMobileClose} className="p-1 rounded text-slate-500 hover:text-white hover:bg-white/5">
          <ChevronLeft className="w-4 h-4" />
        </button>
      </div>
      <nav className="flex-1 overflow-y-auto px-2 py-3 space-y-0.5">
        {navItems.map(item => (
          <NavLink key={item.to} to={item.to} end={item.end} onClick={onMobileClose}
            className={({ isActive }) =>
              `flex items-center gap-3 px-2.5 py-2 rounded-lg text-xs font-medium transition-all ${
                isActive ? 'bg-indigo-500/10 text-indigo-300 border border-indigo-500/10' : 'text-slate-400 border border-transparent hover:bg-white/5 hover:text-white'
              } ${lang === 'ar' ? 'flex-row-reverse' : ''}`
            }
          >
            <item.icon className="w-4 h-4 shrink-0" />
            <span className="truncate">{t(item.label)}</span>
          </NavLink>
        ))}
      </nav>
      <div className="p-3 border-t border-white/5">
        <button onClick={() => logout()} className={`flex items-center gap-3 px-2.5 py-2 rounded-lg text-xs text-slate-500 hover:text-rose-400 hover:bg-rose-500/5 w-full transition-all ${lang === 'ar' ? 'flex-row-reverse' : ''}`}>
          <LogOut className="w-4 h-4 shrink-0" />
          <span>{t('sign.out')}</span>
        </button>
      </div>
    </aside>
    {/* Desktop sidebar */}
    <aside className={`${collapsed ? 'w-16' : 'w-56'} transition-all duration-300 border-r border-white/5 bg-[#0D0D0E] flex-col shrink-0 ${lang === 'ar' ? 'border-l border-r-0' : ''} hidden lg:flex`}>
      <div className="p-4 flex items-center justify-between border-b border-white/5 h-14">
        {!collapsed && (
          <div className={`flex items-center gap-2 ${lang === 'ar' ? 'flex-row-reverse' : ''}`}>
            <div className="w-7 h-7 rounded bg-indigo-600 flex items-center justify-center text-white font-bold text-xs">Z</div>
            <span className="text-white font-semibold text-sm" style={{ fontFamily: lang === 'ar' ? 'system-ui' : 'inherit' }}>{t('app.name')}</span>
          </div>
        )}
        <button onClick={onToggle} className="p-1 rounded text-slate-500 hover:text-white hover:bg-white/5">
          <ChevronLeft className={`w-4 h-4 transition-transform ${collapsed ? 'rotate-180' : ''} ${lang === 'ar' ? 'rotate-180' : ''}`} />
        </button>
      </div>
      <nav className="flex-1 overflow-y-auto px-2 py-3 space-y-0.5">
        {navItems.map(item => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.end}
            className={({ isActive }) =>
              `flex items-center gap-3 px-2.5 py-2 rounded-lg text-xs font-medium transition-all ${
                isActive
                  ? 'bg-indigo-500/10 text-indigo-300 border border-indigo-500/10'
                  : 'text-slate-400 border border-transparent hover:bg-white/5 hover:text-white'
              } ${lang === 'ar' ? 'flex-row-reverse' : ''}`
            }
            title={collapsed ? t(item.label) : undefined}
          >
            <item.icon className="w-4 h-4 shrink-0" />
            {!collapsed && <span className="truncate">{t(item.label)}</span>}
          </NavLink>
        ))}
      </nav>
      <div className="p-3 border-t border-white/5">
        <button
          onClick={() => logout()}
          className={`flex items-center gap-3 px-2.5 py-2 rounded-lg text-xs text-slate-500 hover:text-rose-400 hover:bg-rose-500/5 w-full transition-all ${lang === 'ar' ? 'flex-row-reverse' : ''}`}
          title={t('sign.out')}
        >
          <LogOut className="w-4 h-4 shrink-0" />
          {!collapsed && <span>{t('sign.out')}</span>}
        </button>
      </div>
    </aside>
    </>
  );
}
