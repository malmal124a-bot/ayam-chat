import { useEffect, useState } from 'react';
import { getAppConfig, updateAppConfig } from '../lib/db';
import { uploadAppAsset } from '../lib/storage';
import { to6Hex } from '../lib/colors';
import { Save, RotateCcw, Upload, X } from 'lucide-react';

const defaults: Record<string, string> = {
  giftBoxBgColor: '#0F172A',
  giftBoxRadius: '32',
  giftBoxBgImage: '',
  giftTileBgColor: '#05FFFFFF',
  giftTileSelectedColor: '#1AFFC107',
  giftTileRadius: '16',
  giftTileBgImage: '',
  giftTileBorderColor: '#1AFFFFFF',
  giftTileSelectedBorderColor: '#FFC107',
};

const colorFields: { key: string; label: string }[] = [
  { key: 'giftBoxBgColor', label: 'لون خلفية الصندوق' },
  { key: 'giftTileBgColor', label: 'لون خلفية مربع الهدية' },
  { key: 'giftTileSelectedColor', label: 'لون مربع الهدية المحدد' },
  { key: 'giftTileBorderColor', label: 'لون إطار المربع' },
  { key: 'giftTileSelectedBorderColor', label: 'لون إطار المربع المحدد' },
];

const imageFields: { key: string; label: string }[] = [
  { key: 'giftBoxBgImage', label: 'صورة خلفية الصندوق (اختياري)' },
  { key: 'giftTileBgImage', label: 'صورة مربع عرض الهدية (اختياري)' },
];

export default function GiftBoxCustomizePage() {
  const [config, setConfig] = useState<Record<string, string>>({ ...defaults });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getAppConfig().then(data => {
      if (data) {
        const merged: Record<string, string> = { ...defaults };
        for (const key of Object.keys(defaults)) {
          const v = data[key as keyof typeof data];
          if (v !== undefined && v !== null) merged[key] = String(v);
        }
        setConfig(merged);
      }
      setLoading(false);
    });
  }, []);

  const handleSave = async () => {
    await updateAppConfig(config);
    alert('تم حفظ إعدادات صندوق الهدايا! ستظهر عند فتح صندوق الهدايا في التطبيق.');
  };

  const resetToDefaults = () => {
    if (confirm('إعادة كل إعدادات صندوق الهدايا للوضع الافتراضي؟')) {
      setConfig({ ...defaults });
    }
  };

  const update = (key: string, value: string) => setConfig(p => ({ ...p, [key]: value }));

  const pickAndUpload = (key: string) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.onchange = async () => {
      const file = input.files?.[0];
      if (!file) return;
      try {
        const url = await uploadAppAsset(file, key);
        update(key, url);
      } catch (err) {
        alert('فشل الرفع: ' + (err as Error).message);
      }
    };
    input.click();
  };

  if (loading) return <div className="text-slate-500 text-xs">Loading...</div>;

  return (
    <div className="space-y-6 max-w-2xl" dir="rtl">
      <div>
        <h2 className="text-white text-lg font-semibold">تخصيص صندوق الهدايا 🎁</h2>
        <p className="text-slate-500 text-xs mt-0.5">
          تحكم في شكل الصندوق وخلفيته وصورة مربع عرض الهدية داخل صندوق الهدايا. تُحفظ القيم في جدول app_config وتُطبق في التطبيق.
        </p>
      </div>

      {/* Box background + shape */}
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
        <h3 className="text-white text-sm font-semibold">شكل الصندوق وخلفيته</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">استدارة زوايا الصندوق (0 - 64)</label>
            <input
              type="number" min={0} max={64}
              value={config.giftBoxRadius}
              onChange={e => update('giftBoxRadius', e.target.value)}
              className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono"
            />
          </div>
          <div>
            <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">استدارة زوايا مربع الهدية (0 - 32)</label>
            <input
              type="number" min={0} max={32}
              value={config.giftTileRadius}
              onChange={e => update('giftTileRadius', e.target.value)}
              className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {colorFields.map(({ key, label }) => (
            <div key={key}>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">{label}</label>
              <div className="flex gap-2 items-center">
                <input
                  type="color"
                  value={to6Hex(config[key] || defaults[key])}
                  onChange={e => update(key, e.target.value)}
                  className="w-10 h-10 rounded cursor-pointer bg-transparent border border-white/10 shrink-0"
                />
                <input
                  type="text"
                  value={config[key]}
                  onChange={e => update(key, e.target.value)}
                  className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono"
                />
                <button
                  onClick={() => update(key, defaults[key])}
                  className="text-[10px] text-slate-500 hover:text-white p-1"
                  title="إعادة الافتراضي"
                >
                  <RotateCcw className="w-3 h-3" />
                </button>
              </div>
              <div className="mt-1 h-2 rounded" style={{ backgroundColor: config[key] || defaults[key] }} />
            </div>
          ))}
        </div>
      </div>

      {/* Images */}
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
        <h3 className="text-white text-sm font-semibold">صور الصندوق</h3>
        {imageFields.map(({ key, label }) => {
          const url = config[key];
          return (
            <div key={key}>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">{label}</label>
              <div className="flex gap-3 items-center">
                <div className="w-20 h-20 rounded-lg overflow-hidden border border-white/10 bg-black/30 flex items-center justify-center shrink-0">
                  {url ? (
                    <img src={url} className="w-full h-full object-cover" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
                  ) : (
                    <span className="text-[8px] text-slate-600">بدون صورة</span>
                  )}
                </div>
                <div className="flex flex-col gap-1.5 flex-1">
                  <input
                    type="text"
                    value={url}
                    onChange={e => update(key, e.target.value)}
                    placeholder="رابط الصورة أو ارفع صورة"
                    className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-[10px] text-white font-mono"
                  />
                  <div className="flex gap-2">
                    <button
                      onClick={() => pickAndUpload(key)}
                      className="flex items-center gap-1 text-[10px] px-3 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white"
                    >
                      <Upload className="w-3 h-3" /> رفع صورة
                    </button>
                    {url && (
                      <button
                        onClick={() => update(key, '')}
                        className="flex items-center gap-1 text-[10px] px-3 py-1.5 rounded-lg border border-white/10 text-slate-400 hover:text-white"
                      >
                        <X className="w-3 h-3" /> مسح
                      </button>
                    )}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="flex gap-3 pt-2">
        <button onClick={handleSave} className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1.5">
          <Save className="w-3.5 h-3.5" /> حفظ الإعدادات
        </button>
        <button onClick={resetToDefaults} className="px-5 py-2 border border-white/10 text-xs text-slate-400 rounded-lg hover:bg-white/5">
          إعادة الافتراضي
        </button>
      </div>
    </div>
  );
}
