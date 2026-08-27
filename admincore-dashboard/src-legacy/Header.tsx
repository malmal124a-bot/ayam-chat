import { useLocation } from 'react-router-dom';
import { Bell, Search, X, Languages, Menu } from 'lucide-react';
import { useState, useContext } from 'react';
import { I18nContext, langs } from '../lib/i18n';

const pageTitles: Record<string, string> = {
  '/': 'nav.dashboard',
  '/users': 'nav.users',
  '/gifts': 'nav.gifts',
  '/store': 'nav.store',
  '/rooms': 'nav.rooms',
  '/unions': 'nav.unions',
  '/vip': 'nav.vip',
  '/levels': 'nav.levels',
  '/badges': 'nav.badges',
  '/banners': 'nav.banners',
  '/agency': 'nav.agency',
  '/cp': 'nav.cp',
  '/bd': 'nav.bd',
  '/app-assets': 'nav.appAssets',
  '/image-customize': 'nav.images',
  '/color-customize': 'nav.colors',
  '/error-analysis': 'nav.errors',
  '/notifications': 'nav.notifications',
  '/settings': 'nav.settings',
};

export default function Header({ onMenuClick }: { onMenuClick?: () => void }) {
  const location = useLocation();
  const { t, lang, setLang } = useContext(I18nContext);
  const [search, setSearch] = useState('');
  const [showLang, setShowLang] = useState(false);
  const titleKey = pageTitles[location.pathname] || '';
  const title = titleKey ? t(titleKey) : 'Admin';

  return (
    <header className={`h-14 shrink-0 border-b border-white/5 flex items-center justify-between px-3 lg:px-6 bg-[#0D0D0E] ${lang === 'ar' ? 'flex-row-reverse' : ''}`}>
      <div className={`flex items-center gap-2 ${lang === 'ar' ? 'flex-row-reverse' : ''}`}>
        <button onClick={onMenuClick} className="lg:hidden p-1.5 rounded text-slate-400 hover:text-white hover:bg-white/5">
          <Menu className="w-4 h-4" />
        </button>
        <div className={`flex items-center gap-3 ${lang === 'ar' ? 'flex-row-reverse' : ''}`}>
          <span className="text-slate-500 text-xs uppercase tracking-wider font-bold hidden sm:inline">Zero</span>
          <span className="text-slate-600 text-sm hidden sm:inline">/</span>
          <span className="text-white text-xs uppercase tracking-wider font-bold">{title}</span>
        </div>
      </div>
      <div className={`flex items-center gap-4 ${lang === 'ar' ? 'flex-row-reverse' : ''}`}>
        <div className="relative">
          <Search className={`w-3.5 h-3.5 absolute top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none ${lang === 'ar' ? 'right-3' : 'left-3'}`} />
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder={t('search')}
            className={`bg-[#161618] border border-white/10 rounded-full py-1.5 ${lang === 'ar' ? 'pr-9 pl-4' : 'pl-9 pr-4'} text-xs w-36 sm:w-48 text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600`}
          />
          {search && (
            <button onClick={() => setSearch('')} className={`absolute top-1/2 -translate-y-1/2 text-slate-400 hover:text-white ${lang === 'ar' ? 'left-3' : 'right-3'}`}>
              <X className="w-3 h-3" />
            </button>
          )}
        </div>
        <div className="relative">
          <button onClick={() => setShowLang(!showLang)} className="p-1.5 rounded-full border border-white/5 bg-[#141417] text-slate-400 hover:text-white">
            <Languages className="w-3.5 h-3.5" />
          </button>
          {showLang && (
            <div className={`absolute top-full mt-1 ${lang === 'ar' ? 'left-0' : 'right-0'} bg-[#1c1c1f] border border-white/10 rounded-lg py-1 min-w-[100px] z-50 shadow-xl`}>
              {langs.map(l => (
                <button key={l.code} onClick={() => { setLang(l.code); setShowLang(false); }} className={`w-full text-left px-3 py-1.5 text-xs ${lang === l.code ? 'text-indigo-400 bg-indigo-500/10' : 'text-slate-400 hover:text-white hover:bg-white/5'}`}>
                  {l.label}
                </button>
              ))}
            </div>
          )}
        </div>
        <div className={`flex items-center gap-2.5 pl-2 border-l border-white/5 ${lang === 'ar' ? 'flex-row-reverse' : ''}`}>
          <div className="w-7 h-7 rounded-full bg-gradient-to-tr from-indigo-600 to-rose-500 flex items-center justify-center font-bold text-[11px] text-white select-none shadow-md">
            A
          </div>
          <div className={`hidden lg:flex flex-col ${lang === 'ar' ? 'text-right' : ''}`}>
            <span className="text-xs text-white font-medium leading-tight">Admin</span>
            <span className="text-[9px] text-slate-500 font-mono leading-none">Super Admin</span>
          </div>
        </div>
      </div>
    </header>
  );
}
