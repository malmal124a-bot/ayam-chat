import { useContext, useEffect, useState } from 'react';
import { I18nContext } from '../lib/i18n';
import { getAppConfig, updateAppConfig } from '../lib/db';
import { iconRegistry, IconRegistryEntry } from '../lib/iconRegistry';
import { uploadAppAsset } from '../lib/storage';
import { Search, Upload, ImageIcon, Film, Save, RotateCcw, Eye, ExternalLink } from 'lucide-react';

const categories = Array.from(new Set(iconRegistry.map(e => e.category))).sort();

export default function AppIconsPage() {
  const { t, lang } = useContext(I18nContext);
  const [overrides, setOverrides] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [msg, setMsg] = useState('');
  const [previewIcon, setPreviewIcon] = useState<string | null>(null);

  const showMsg = (text: string) => { setMsg(text); setTimeout(() => setMsg(''), 3000); };

  useEffect(() => {
    (async () => {
      try {
        const cfg = await getAppConfig();
        const saved = cfg?.iconOverrides as Record<string, string> | undefined;
        if (saved) setOverrides(saved);
      } catch (e) { console.warn(e); }
      setLoading(false);
    })();
  }, []);

  const filtered = iconRegistry.filter(e => {
    if (categoryFilter && e.category !== categoryFilter) return false;
    if (search) {
      const q = search.toLowerCase();
      return e.key.toLowerCase().includes(q) || e.name.toLowerCase().includes(q);
    }
    return true;
  });

  const handleUpload = async (file: File, key: string) => {
    try {
      const path = `icon_overrides/${key.replace('.', '_')}_${Date.now()}`;
      const url = await uploadAppAsset(file, path);
      if (url) {
        setOverrides(prev => ({ ...prev, [key]: url }));
      }
    } catch {
      showMsg(lang === 'ar' ? 'فشل رفع الملف' : 'Upload failed');
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateAppConfig({ iconOverrides: overrides } as any);
      showMsg(lang === 'ar' ? 'تم الحفظ!' : 'Saved!');
    } catch {
      showMsg(lang === 'ar' ? 'فشل الحفظ' : 'Save failed');
    }
    setSaving(false);
  };

  const handleReset = () => {
    if (confirm(lang === 'ar' ? 'إعادة تعيين جميع الأيقونات؟' : 'Reset all icon overrides?')) {
      setOverrides({});
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <ImageIcon className="w-5 h-5 text-indigo-400" />
          <h2 className="text-white text-lg font-semibold">
            {lang === 'ar' ? 'إدارة الأيقونات' : 'Icon Manager'}
          </h2>
          <span className="text-[10px] text-slate-500 bg-white/5 px-2 py-0.5 rounded-full">{iconRegistry.length} icons</span>
        </div>
        <div className="flex gap-2">
          <button onClick={handleReset} className="px-3 py-1.5 bg-rose-600/20 hover:bg-rose-600/30 text-rose-400 text-xs font-semibold rounded-lg">
            <RotateCcw className="w-3.5 h-3.5 inline mr-1" />{lang === 'ar' ? 'إعادة تعيين' : 'Reset'}
          </button>
          <button onClick={handleSave} disabled={saving} className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-xs text-white font-semibold rounded-lg">
            <Save className="w-3.5 h-3.5 inline mr-1" />{saving ? t('saving') : t('save')}
          </button>
        </div>
      </div>

      {msg && <div className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs px-4 py-2 rounded-lg">{msg}</div>}

      {/* Filters */}
      <div className="flex gap-3 flex-wrap">
        <div className="relative flex-1 max-w-xs">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-500" />
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder={lang === 'ar' ? 'بحث...' : 'Search icons...'}
            className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 pl-8 pr-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
        </div>
        <select value={categoryFilter} onChange={e => setCategoryFilter(e.target.value)}
          className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
          <option value="">{lang === 'ar' ? 'كل التصنيفات' : 'All Categories'}</option>
          {categories.map(c => <option key={c} value={c}>{c}</option>)}
        </select>
      </div>

      {/* Icon Grid */}
      {loading ? (
        <div className="text-slate-400 text-sm p-6">{t('loading')}</div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
          {filtered.map(entry => (
            <IconCard
              key={entry.key}
              entry={entry}
              overrideUrl={overrides[entry.key] || ''}
              onOverrideChange={url => setOverrides(prev => ({ ...prev, [entry.key]: url }))}
              onUpload={file => handleUpload(file, entry.key)}
              lang={lang}
            />
          ))}
        </div>
      )}

      {!loading && filtered.length === 0 && (
        <div className="text-slate-500 text-sm text-center py-12">
          {lang === 'ar' ? 'لا توجد أيقونات مطابقة للبحث' : 'No icons match your search'}
        </div>
      )}

      {/* Preview Modal */}
      {previewIcon && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60" onClick={() => setPreviewIcon(null)}>
          <div className="bg-[#141417] rounded-2xl border border-white/10 p-6 max-w-md w-full mx-4" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-white text-sm font-semibold">{lang === 'ar' ? 'معاينة الأيقونة' : 'Icon Preview'}</h3>
              <button onClick={() => setPreviewIcon(null)} className="text-slate-400 hover:text-white text-xs">X</button>
            </div>
            <div className="flex items-center justify-center p-8 bg-[#0d0d12] rounded-xl">
              {previewIcon.startsWith('http') ? (
                previewIcon.endsWith('.svga') ? (
                  <div className="text-amber-400 text-xs">{lang === 'ar' ? 'ملف SVGA - شغّل في التطبيق' : 'SVGA file - play in app'}</div>
                ) : (
                  <img src={previewIcon} alt="Preview" className="max-w-full max-h-48 object-contain rounded" />
                )
              ) : (
                <span className="text-slate-500 text-xs">{lang === 'ar' ? 'لا توجد معاينة' : 'No preview'}</span>
              )}
            </div>
            <p className="text-[10px] text-slate-500 mt-2 text-center break-all">{previewIcon}</p>
          </div>
        </div>
      )}
    </div>
  );
}

function IconCard({ entry, overrideUrl, onOverrideChange, onUpload, lang }: {
  entry: IconRegistryEntry;
  overrideUrl: string;
  onOverrideChange: (url: string) => void;
  onUpload: (file: File) => void;
  lang: string;
}) {
  return (
    <div className="bg-[#141417] rounded-xl border border-white/5 p-3 space-y-2 hover:border-indigo-500/20 transition-colors">
      <div className="flex items-center gap-2">
        <div className="w-9 h-9 rounded-lg bg-[#0d0d12] flex items-center justify-center border border-white/5 shrink-0">
          {overrideUrl ? (
            overrideUrl.endsWith('.svga') ? (
              <Film className="w-4 h-4 text-amber-400" />
            ) : (
              <img src={overrideUrl} alt="" className="w-6 h-6 object-contain rounded" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
            )
          ) : (
            <span className="material-icons text-slate-400 text-lg leading-none">{entry.icon}</span>
          )}
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-xs text-white font-medium truncate">{entry.name}</p>
          <p className="text-[10px] text-slate-500 font-mono truncate">{entry.key}</p>
        </div>
      </div>

      <div className="flex gap-1.5">
        <input value={overrideUrl} onChange={e => onOverrideChange(e.target.value)}
          placeholder={lang === 'ar' ? 'رابط الصورة/SVGA/VAP' : 'Image/SVGA/VAP URL'}
          className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-1 px-2 text-[10px] text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
        <label className="cursor-pointer px-1.5 py-1 bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-400 rounded-lg">
          <Upload className="w-3 h-3" />
          <input type="file" accept="image/*,.svga,.vap,.mp4,.gif,.webp,.png" className="hidden"
            onChange={e => { const f = e.target.files?.[0]; if (f) onUpload(f); }} />
        </label>
      </div>

      <div className="flex items-center justify-between">
        <span className="text-[9px] text-slate-600 bg-white/5 px-1.5 py-0.5 rounded">{entry.category}</span>
        {overrideUrl && (
          <button onClick={() => window.open(overrideUrl, '_blank')} className="text-[9px] text-indigo-400 hover:text-indigo-300 flex items-center gap-0.5">
            <ExternalLink className="w-2.5 h-2.5" /> {lang === 'ar' ? 'معاينة' : 'Preview'}
          </button>
        )}
      </div>
      {entry.files.length > 0 && (
        <p className="text-[8px] text-slate-600 truncate" title={entry.files.join(', ')}>
          {entry.files.length} file{entry.files.length > 1 ? 's' : ''}: {entry.files.slice(0, 3).join(', ')}{entry.files.length > 3 ? '...' : ''}
        </p>
      )}
    </div>
  );
}
