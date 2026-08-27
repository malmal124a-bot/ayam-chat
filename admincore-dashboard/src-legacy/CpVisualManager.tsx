import { useEffect, useState } from 'react';
import { getAppConfig, updateAppConfig } from '../lib/db';
import { uploadAppAsset } from '../lib/storage';
import { Save, Upload, Image } from 'lucide-react';

interface CpVisualState {
  cp: Record<string, string>;
}

const backgroundFields = [
  'backgroundImage', 'headerBgImage', 'fullScreenBg', 'cabinBg',
  'cabinDefaultBg', 'mineBg', 'sectionBgImage', 'rankBgImage',
  'invitationBgImage', 'tabBgImage',
];

const frameFields = [
  'leftFrame', 'rightFrame', 'cardBgImage', 'cardBorderImage',
  'headerTextImage', 'textImage', 'subTextImage', 'accentImage',
  'lockImage',
];

const svgFields = [
  'heartImage', 'noCpHeartSvg', 'tokenBg',
  'countdownDaySvg', 'countdownHourSvg', 'countdownMinSvg', 'countdownSecSvg',
  'rankTagGoldSvg', 'rankTagSilverSvg', 'rankTagBronzeSvg',
  'historyCardSvg', 'giftsBannerSvg',
];

const imageFields = [...backgroundFields, ...frameFields, ...svgFields];

const fieldLabels: Record<string, Record<string, string>> = {
  backgroundImage: { ar: 'صورة الخلفية', en: 'Background Image' },
  headerBgImage: { ar: 'صورة خلفية الرأس', en: 'Header Background Image' },
  fullScreenBg: { ar: 'صورة خلفية كاملة', en: 'Full Screen Background' },
  cabinBg: { ar: 'خلفية الكابينة', en: 'Cabin Background' },
  cabinDefaultBg: { ar: 'خلفية الكابينة الافتراضية', en: 'Cabin Default BG' },
  mineBg: { ar: 'خلفية My CP', en: 'My CP Background' },
  sectionBgImage: { ar: 'صورة خلفية القسم', en: 'Section BG Image' },
  rankBgImage: { ar: 'صورة خلفية الترتيب', en: 'Rank BG Image' },
  invitationBgImage: { ar: 'صورة خلفية الدعوة', en: 'Invitation BG Image' },
  tabBgImage: { ar: 'صورة خلفية التبويب', en: 'Tab BG Image' },
  leftFrame: { ar: 'إطار الأفاتار الأيسر', en: 'Left Avatar Frame' },
  rightFrame: { ar: 'إطار الأفاتار الأيمن', en: 'Right Avatar Frame' },
  cardBgImage: { ar: 'صورة خلفية البطاقة', en: 'Card BG Image' },
  cardBorderImage: { ar: 'صورة حدود البطاقة', en: 'Card Border Image' },
  headerTextImage: { ar: 'صورة نص الرأس', en: 'Header Text Image' },
  textImage: { ar: 'صورة النص', en: 'Text Image' },
  subTextImage: { ar: 'صورة النص الثانوي', en: 'Sub Text Image' },
  accentImage: { ar: 'صورة التمييز', en: 'Accent Image' },
  lockImage: { ar: 'صورة القفل', en: 'Lock Image' },
  heartImage: { ar: 'صورة القلب', en: 'Heart Image' },
  noCpHeartSvg: { ar: 'صورة القلب (بدون شريك)', en: 'No-CP Heart SVG' },
  tokenBg: { ar: 'خلفية النقاط', en: 'Token Background' },
  countdownDaySvg: { ar: 'أيقونة الأيام', en: 'Days Icon SVG' },
  countdownHourSvg: { ar: 'أيقونة الساعات', en: 'Hours Icon SVG' },
  countdownMinSvg: { ar: 'أيقونة الدقائق', en: 'Minutes Icon SVG' },
  countdownSecSvg: { ar: 'أيقونة الثواني', en: 'Seconds Icon SVG' },
  rankTagGoldSvg: { ar: 'وسام الذهبية', en: 'Gold Rank Tag SVG' },
  rankTagSilverSvg: { ar: 'وسام الفضية', en: 'Silver Rank Tag SVG' },
  rankTagBronzeSvg: { ar: 'وسام البرونزية', en: 'Bronze Rank Tag SVG' },
  historyCardSvg: { ar: 'خلفية بطاقة التاريخ', en: 'History Card BG SVG' },
  giftsBannerSvg: { ar: 'خلفية هدايا CP', en: 'CP Gifts Banner BG SVG' },
};

const defaultValues: Record<string, string> = {};

const categoryConfig = [
  {
    id: 'backgrounds',
    titleAr: '🖼 خلفيات CP',
    titleEn: 'CP Backgrounds',
    fields: backgroundFields,
  },
  {
    id: 'frames',
    titleAr: '🖼 إطارات وصور',
    titleEn: 'Frames & Images',
    fields: frameFields,
  },
  {
    id: 'svgs',
    titleAr: '🎨 SVG وأيقونات',
    titleEn: 'SVGs & Icons',
    fields: svgFields,
  },
];

export default function CpVisualManagerPage() {
  const [values, setValues] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState('');
  const [activeCategory, setActiveCategory] = useState('backgrounds');

  useEffect(() => {
    (async () => {
      try {
        const cfg = await getAppConfig();
        const cp = (cfg as any)?.screenVisuals?.cp;
        if (cp && typeof cp === 'object') {
          const merged: Record<string, string> = {};
          for (const field of imageFields) {
            merged[field] = cp[field] || '';
          }
          setValues(merged);
        }
      } catch (e) { console.warn(e); }
      setLoading(false);
    })();
  }, []);

  const showMsg = (text: string) => { setMsg(text); setTimeout(() => setMsg(''), 3000); };

  const updateField = (field: string, value: string) => {
    setValues(prev => ({ ...prev, [field]: value }));
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const cfg = await getAppConfig();
      const screenVisuals = ((cfg as any)?.screenVisuals || {}) as Record<string, any>;
      const clean: Record<string, string> = {};
      for (const field of imageFields) {
        const v = values[field];
        if (v && v.trim()) clean[field] = v.trim();
      }
      await updateAppConfig({
        screenVisuals: { ...screenVisuals, cp: { ...(screenVisuals.cp || {}), ...clean } },
      } as any);
      showMsg('تم الحفظ!');
    } catch (e) {
      showMsg('فشل الحفظ');
      console.warn(e);
    }
    setSaving(false);
  };

  const handleImageUpload = async (file: File, field: string) => {
    try {
      const path = `cp_visuals/${field}_${Date.now()}`;
      const url = await uploadAppAsset(file, path);
      if (url) updateField(field, url);
    } catch {
      showMsg('فشل رفع الصورة');
    }
  };

  if (loading) return <div className="text-slate-400 text-sm p-6">جاري التحميل...</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">💑 مدير صور CP</h2>
          <p className="text-slate-500 text-xs mt-0.5">CP Visual Asset Manager — إدارة جميع صور ورسومات CP</p>
        </div>
        <button onClick={handleSave} disabled={saving}
          className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-xs text-white font-semibold rounded-lg flex items-center gap-1.5">
          <Save className="w-3.5 h-3.5" /> {saving ? 'جاري الحفظ...' : 'حفظ الكل'}
        </button>
      </div>

      {msg && <div className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs px-4 py-2 rounded-lg">{msg}</div>}

      {/* Category tabs */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {categoryConfig.map(cat => (
          <button key={cat.id} onClick={() => setActiveCategory(cat.id)}
            className={`px-4 py-2 rounded-lg text-xs font-medium whitespace-nowrap transition-all ${
              activeCategory === cat.id
                ? 'bg-indigo-500/10 text-indigo-300 border border-indigo-500/10'
                : 'text-slate-400 border border-transparent hover:bg-white/5 hover:text-white'
            }`}>
            {cat.titleAr}
          </button>
        ))}
      </div>

      {/* Fields grid */}
      {categoryConfig.map(cat => (
        <div key={cat.id} className={`space-y-4 ${activeCategory !== cat.id ? 'hidden' : ''}`}>
          <div className="bg-[#141417] rounded-2xl border border-white/5 p-6">
            <h3 className="text-white text-sm font-semibold mb-4">{cat.titleAr}</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {cat.fields.map(field => {
                const label = fieldLabels[field]?.ar || field;
                const value = values[field] || '';
                return (
                  <div key={field} className="bg-[#161618] rounded-xl border border-white/5 p-3">
                    <label className="block text-[10px] text-slate-400 font-bold mb-2">{label}</label>
                    {value ? (
                      <div className="relative mb-2">
                        <img src={value} alt={label}
                          className="w-full h-24 object-contain rounded-lg bg-black/30 border border-white/5"
                          onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
                        <button onClick={() => updateField(field, '')}
                          className="absolute -top-2 -right-2 w-5 h-5 rounded-full bg-rose-500 text-white text-[10px] flex items-center justify-center shadow">×</button>
                      </div>
                    ) : (
                      <div className="w-full h-24 rounded-lg bg-black/10 border border-dashed border-white/5 flex flex-col items-center justify-center text-[9px] text-slate-600 mb-2">
                        <Image className="w-5 h-5 mb-1 opacity-40" />
                        لا توجد صورة
                      </div>
                    )}
                    <div className="flex gap-1.5">
                      <label className="flex items-center justify-center gap-1 text-[9px] px-3 py-1.5 rounded-lg border border-white/10 hover:bg-white/5 cursor-pointer flex-1">
                        <Upload className="w-3 h-3" />
                        رفع
                        <input type="file" accept="image/*,.svga,.mp4,.gif,.webp,.svg" className="hidden" onChange={e => {
                          const file = e.target.files?.[0];
                          if (file) handleImageUpload(file, field);
                        }} />
                      </label>
                    </div>
                    <input type="text" value={value}
                      onChange={e => updateField(field, e.target.value)}
                      placeholder="أو ألصق رابط URL..."
                      className="w-full mt-1.5 bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-[10px] text-white font-mono" />
                  </div>
                );
              })}
            </div>
          </div>

          {/* Preview banner */}
          <div className="bg-[#141417] rounded-2xl border border-white/5 p-6">
            <h3 className="text-white text-sm font-semibold mb-3">معاينة سريعة</h3>
            <div className="flex gap-3 items-center justify-center p-6 rounded-xl"
              style={{
                background: values.backgroundImage
                  ? `url(${values.backgroundImage}) center/cover no-repeat`
                  : '#1a1a2e',
              }}>
              <div className="flex flex-col items-center gap-1">
                <div className="w-16 h-16 rounded-full border-2 overflow-hidden"
                  style={{ borderColor: '#E91E8C', background: '#161618' }}>
                  {values.leftFrame ? (
                    <img src={values.leftFrame} className="w-full h-full object-contain" />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-[18px]">👤</div>
                  )}
                </div>
                <span className="text-[10px] text-white/70">User 1</span>
              </div>
              <div className="flex flex-col items-center">
                {values.heartImage ? (
                  <img src={values.heartImage} className="w-8 h-8 object-contain" />
                ) : (
                  <span className="text-[24px]">💕</span>
                )}
                <span className="text-[8px] text-white/50 mt-1">LV 3</span>
              </div>
              <div className="flex flex-col items-center gap-1">
                <div className="w-16 h-16 rounded-full border-2 overflow-hidden"
                  style={{ borderColor: '#E91E8C', background: '#161618' }}>
                  {values.rightFrame ? (
                    <img src={values.rightFrame} className="w-full h-full object-contain" />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-[18px]">👤</div>
                  )}
                </div>
                <span className="text-[10px] text-white/70">User 2</span>
              </div>
            </div>
            <div className="flex gap-2 justify-center mt-3">
              {['countdownDaySvg', 'countdownHourSvg', 'countdownMinSvg', 'countdownSecSvg'].map(f => (
                <div key={f} className="flex items-center gap-1 text-[10px] text-white/60">
                  {values[f] ? (
                    <img src={values[f]} className="w-5 h-5 object-contain" />
                  ) : (
                    <span className="w-5 h-5 rounded bg-white/5 flex items-center justify-center text-[8px]">?</span>
                  )}
                  <span>{f === 'countdownDaySvg' ? '12' : f === 'countdownHourSvg' ? '24' : f === 'countdownMinSvg' ? '60' : '60'}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
