import { useEffect, useState } from 'react';
import { AppConfig } from '../types';
import { getAppConfig, updateAppConfig } from '../lib/db';
import { Save, Palette, RotateCcw } from 'lucide-react';
import { to6Hex } from '../lib/colors';

const defaultColors: Record<string, string> = {
  primaryBg: '#1A1A2E',
  textPrimary: '#FFFFFF',
  textSecondary: '#9BA1B6',
  goldColor: '#B9F2FF',
  buttonColor: '#6F4E37',
  buttonTextColor: '#FFFFFF',
  headerColor: '#1A1A2E',
  tabBarColor: '#6F4E37',
  cardColor: '#6F4E37',
  accentColor: '#B9F2FF',
};

const colorFields: { key: string; label: string; labelAr: string; default: string }[] = [
  { key: 'primaryBg', label: 'Background', labelAr: 'الخلفية', default: '#1A1A2E' },
  { key: 'cardColor', label: 'Card / Surface', labelAr: 'البطاقات والأسطح', default: '#6F4E37' },
  { key: 'headerColor', label: 'Header Bar', labelAr: 'شريط العنوان', default: '#1A1A2E' },
  { key: 'tabBarColor', label: 'Tab Bar', labelAr: 'شريط التنقل', default: '#6F4E37' },
  { key: 'goldColor', label: 'Gold / Accent', labelAr: 'اللون الذهبي / التمييز', default: '#B9F2FF' },
  { key: 'accentColor', label: 'Accent 2', labelAr: 'اللون الثاني للتمييز', default: '#B9F2FF' },
  { key: 'buttonColor', label: 'Button Color', labelAr: 'لون الأزرار', default: '#6F4E37' },
  { key: 'buttonTextColor', label: 'Button Text', labelAr: 'نص الأزرار', default: '#FFFFFF' },
  { key: 'textPrimary', label: 'Primary Text', labelAr: 'النص الأساسي', default: '#FFFFFF' },
  { key: 'textSecondary', label: 'Secondary Text', labelAr: 'النص الثانوي', default: '#9BA1B6' },
];

export default function ColorCustomizePage() {
  const [config, setConfig] = useState<Record<string, string>>({});
  const [screenTitles, setScreenTitles] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    getAppConfig().then(data => {
      if (data) {
        // colorCustomize is stored as a JSON string in app_config
        const colors = (data as any).colorCustomize;
        if (colors && typeof colors === 'object') {
          setConfig(colors);
        }
        const titles = (data as any).screenTitles;
        if (titles && typeof titles === 'object') {
          setScreenTitles(titles);
        }
      }
      setLoading(false);
    });
  }, []);

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateAppConfig({ colorCustomize: config, screenTitles } as any);
      alert('تم حفظ الألوان بنجاح! التطبيق سيستخدم الألوان الجديدة في التحميل التالي.');
    } catch (e) {
      alert('فشل الحفظ: ' + (e as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const resetToDefaults = () => {
    if (confirm('Reset all colors to defaults?')) {
      setConfig({ ...defaultColors });
    }
  };

  const updateColor = (field: string, value: string) => setConfig(p => ({ ...p, [field]: value }));

  if (loading) return <div className="text-slate-500 text-xs">Loading...</div>;

  // Preview
  const bg = config.primaryBg || defaultColors.primaryBg;
  const card = config.cardColor || defaultColors.cardColor;
  const gold = config.goldColor || defaultColors.goldColor;
  const btn = config.buttonColor || defaultColors.buttonColor;
  const header = config.headerColor || defaultColors.headerColor;

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h2 className="text-white text-lg font-semibold">تخصيص ألوان التطبيق</h2>
        <p className="text-slate-500 text-xs mt-0.5">غيّر ألوان التطبيق — التغييرات تُطبّق فوراً في التطبيق</p>
      </div>

      {/* Live Preview */}
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-4">
        <h3 className="text-white text-xs font-semibold mb-3">معاينة مباشرة</h3>
        <div className="flex gap-2 overflow-x-auto pb-2">
          {/* Phone mockup */}
          <div className="shrink-0 w-48 rounded-xl overflow-hidden border border-white/10" style={{ background: bg }}>
            <div className="h-6 flex items-center justify-center text-[8px] font-bold" style={{ background: header, color: '#fff' }}>Header</div>
            <div className="p-2 space-y-1.5">
              <div className="rounded-lg p-2 text-[8px] text-white" style={{ background: card }}>
                <div className="font-bold" style={{ color: gold }}>عنصر 1</div>
                <div className="text-white/60 text-[7px]">وصف العنصر</div>
              </div>
              <div className="rounded-lg p-2 text-[8px] text-white" style={{ background: card }}>
                <div className="font-bold" style={{ color: gold }}>عنصر 2</div>
              </div>
              <button className="w-full rounded-md py-1 text-[8px] font-bold text-white" style={{ background: btn }}>زر</button>
            </div>
          </div>
        </div>
      </div>

      {/* Color Fields */}
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {colorFields.map(({ key, label, labelAr, default: def }) => (
            <div key={key}>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">
                {labelAr} <span className="text-slate-600">({label})</span>
              </label>
              <div className="flex gap-2 items-center">
                <input
                  type="color"
                  value={to6Hex(config[key] || def)}
                  onChange={e => updateColor(key, e.target.value)}
                  className="w-10 h-10 rounded cursor-pointer bg-transparent border border-white/10 shrink-0"
                />
                <input
                  type="text"
                  value={config[key] || def}
                  onChange={e => updateColor(key, e.target.value)}
                  className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono"
                />
                <button
                  onClick={() => updateColor(key, def)}
                  className="text-[10px] text-slate-500 hover:text-white p-1"
                  title="Reset to default"
                >
                  <RotateCcw className="w-3 h-3" />
                </button>
              </div>
              <div className="mt-1 h-2 rounded" style={{ backgroundColor: config[key] || def }} />
            </div>
          ))}
        </div>

        <div className="flex gap-3 pt-2">
          <button onClick={handleSave} disabled={saving} className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1.5 disabled:opacity-50">
            <Palette className="w-3.5 h-3.5" /> {saving ? 'جاري الحفظ...' : 'حفظ الألوان'}
          </button>
          <button onClick={resetToDefaults} className="px-5 py-2 border border-white/10 text-xs text-slate-400 rounded-lg hover:bg-white/5">
            إعادة التعيين
          </button>
        </div>
      </div>

      {/* Screen Titles */}
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6">
        <h3 className="text-white text-sm font-semibold mb-4">عناوين الشاشات</h3>
        <p className="text-[10px] text-slate-500 mb-4">غيّر عناوين الشاشات في التطبيق</p>
        <div className="grid grid-cols-2 gap-3">
          {[
            { key: 'home', label: 'الرئيسية' },
            { key: 'rooms', label: 'الغرف' },
            { key: 'store', label: 'المتجر' },
            { key: 'profile', label: 'الملف الشخصي' },
            { key: 'gifts', label: 'الهدايا' },
            { key: 'ranking', label: 'التصنيف' },
            { key: 'unions', label: 'الاتحادات' },
            { key: 'vip', label: 'VIP' },
            { key: 'settings', label: 'الإعدادات' },
            { key: 'chat', label: 'المحادثة' },
          ].map(({ key, label }) => (
            <div key={key}>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{label}</label>
              <input
                type="text"
                value={screenTitles[key] || ''}
                onChange={e => setScreenTitles(p => ({ ...p, [key]: e.target.value }))}
                placeholder={label}
                className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
              />
            </div>
          ))}
        </div>
        <button onClick={handleSave} disabled={saving} className="mt-4 px-4 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg">
          حفظ العناوين
        </button>
      </div>
    </div>
  );
}
