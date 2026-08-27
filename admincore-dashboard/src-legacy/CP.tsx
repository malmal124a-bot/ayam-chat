import { useEffect, useState } from 'react';
import { CPModel } from '../types';
import { getCPs, getAppConfig, updateAppConfig } from '../lib/db';
import { uploadAppAsset, uploadToCloudinary } from '../lib/storage';
import DataTable from '../components/DataTable';
import { Upload, Globe, Image, Palette, Save, RotateCcw } from 'lucide-react';
import { to6Hex } from '../lib/colors';

const defaultCpColors: Record<string, string> = {
  cpPrimaryColor: '#E91E8C',
  cpGoldColor: '#FFD700',
  cpBgColor: '#FCE4EC',
  cpTextColor: '#5D1A3A',
  cpHeaderTextColor: '#FFFFFF',
  cpGradientStart: '#E91E8C',
  cpGradientEnd: '#FF4FA3',
};

const cpColorLabels: Record<string, string> = {
  cpPrimaryColor: 'اللون الأساسي (Primary)',
  cpGoldColor: 'الذهبي (Gold)',
  cpBgColor: 'خلفية الصفحة (Background)',
  cpTextColor: 'لون النص (Text)',
  cpHeaderTextColor: 'نص الرأس (Header Text)',
  cpGradientStart: 'بداية التدرج (Gradient Start)',
  cpGradientEnd: 'نهاية التدرج (Gradient End)',
};

const cpImageKeys = [
  { key: 'cpCabinBg', label: 'خلفية الكابينة (Cabin BG)', default: 'assets/cp/Frame 1.svg' },
  { key: 'cpLeftFrame', label: 'إطار الأفاتار الأيسر (Left Frame)', default: 'icon_cp_left_frame' },
  { key: 'cpRightFrame', label: 'إطار الأفاتار الأيمن (Right Frame)', default: 'icon_cp_right_frame' },
  { key: 'cpTokenBg', label: 'خلفية التوكن (Token BG)', default: 'voiceroom_cp_token_bg 1' },
  { key: 'cpHeartBg', label: 'قلب CP (Heart BG)', default: 'ic_cp_heart_bg 2' },
  { key: 'cpMineBg', label: 'خلفية My CP (Mine BG)', default: 'donia_mine_cp_bg 1' },
];

export default function CPPage() {
  const [cps, setCps] = useState<CPModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [cpWebUrl, setCpWebUrl] = useState('');
  const [cpColors, setCpColors] = useState<Record<string, string>>({...defaultCpColors});
  const [cpImages, setCpImages] = useState<Record<string, string>>({});

  useEffect(() => {
    getCPs().then(data => { setCps(data); setLoading(false); });
    getAppConfig().then(cfg => {
      if (cfg?.cpWebUrl) setCpWebUrl(cfg.cpWebUrl as string);
      const colors: Record<string, string> = {};
      for (const key of Object.keys(defaultCpColors)) {
        colors[key] = (cfg as any)?.[key] || defaultCpColors[key];
      }
      setCpColors(colors);
      const images: Record<string, string> = {};
      for (const item of cpImageKeys) {
        images[item.key] = (cfg as any)?.[item.key] || '';
      }
      setCpImages(images);
    });
  }, []);

  const updateColor = (key: string, value: string) =>
    setCpColors(p => ({ ...p, [key]: value }));

  const updateImage = (key: string, value: string) =>
    setCpImages(p => ({ ...p, [key]: value }));

  const saveAll = async () => {
    setSaving(true);
    const payload: Record<string, any> = {
      cpWebUrl,
      ...cpColors,
      ...cpImages,
    };
    await updateAppConfig(payload as any);
    setSaving(false);
  };

  return (
    <div className="space-y-8">
      {/* Content Provider table */}
      <div>
        <h2 className="text-white text-lg font-semibold">Content Provider (CP) Management</h2>
        <p className="text-slate-500 text-xs mt-0.5">{cps.length} content providers</p>
        <DataTable
          loading={loading}
          columns={[
            { key: 'name', label: 'Name', sortable: true },
            { key: 'contactName', label: 'Contact' },
            { key: 'contactEmail', label: 'Email' },
            { key: 'revenueShare', label: 'Revenue Share', sortable: true, render: c => <span>{c.revenueShare}%</span> },
            { key: 'contentCount', label: 'Content Count', sortable: true },
            { key: 'status', label: 'Status', sortable: true, render: c => <span className={c.status === 'active' ? 'text-emerald-400' : 'text-rose-400'}>{c.status}</span> },
          ]}
          data={cps}
          searchKeys={['name', 'contactName', 'contactEmail']}
        />
      </div>

      {/* CP (Couple) Customization */}
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-6">
        <div className="flex items-center justify-between">
          <h3 className="text-white text-sm font-semibold">💑 تخصيص شاشات CP</h3>
          <button onClick={saveAll} disabled={saving}
            className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-xs text-white font-semibold rounded-lg flex items-center gap-1.5">
            <Save className="w-3.5 h-3.5" /> {saving ? 'جاري الحفظ...' : 'حفظ الكل'}
          </button>
        </div>

        {/* WebView URL */}
        <div className="border-t border-white/5 pt-4">
          <label className="block text-[10px] text-slate-400 font-bold mb-1.5 flex items-center gap-1">
            <Globe className="w-3 h-3" /> رابط WebView CP (احتياطي)
          </label>
          <div className="flex gap-2">
            <input type="text" value={cpWebUrl}
              onChange={e => setCpWebUrl(e.target.value)}
              placeholder="https://example.com/cp.html"
              className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono" />
          </div>
          <p className="text-[8px] text-slate-600 mt-1">يمكنك ترك هذا فارغًا إذا كنت تستخدم شاشات CP المدمجة.</p>
        </div>

        {/* Colors */}
        <div className="border-t border-white/5 pt-4">
          <h4 className="text-xs text-amber-300 font-semibold mb-3 flex items-center gap-1">
            <Palette className="w-3 h-3" /> ألوان CP
          </h4>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {Object.entries(defaultCpColors).map(([key, def]) => {
              const val = cpColors[key] || def;
              return (
                <div key={key}>
                  <label className="block text-[10px] text-slate-400 font-bold mb-1.5">{cpColorLabels[key] || key}</label>
                  <div className="flex gap-2 items-center">
                    <input type="color" value={to6Hex(val)}
                      onChange={e => updateColor(key, e.target.value)}
                      className="w-10 h-10 rounded cursor-pointer bg-transparent border border-white/10 shrink-0" />
                    <input type="text" value={val}
                      onChange={e => updateColor(key, e.target.value)}
                      className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono text-left" />
                    <button onClick={() => updateColor(key, def)}
                      className="text-[10px] text-slate-500 hover:text-white p-1 shrink-0" title="إعادة للافتراضي">
                      <RotateCcw className="w-3 h-3" />
                    </button>
                  </div>
                  <div className="mt-1 w-full h-2 rounded" style={{ backgroundColor: to6Hex(val) }} />
                </div>
              );
            })}
          </div>
        </div>

        {/* Custom Images */}
        <div className="border-t border-white/5 pt-4">
          <h4 className="text-xs text-amber-300 font-semibold mb-3 flex items-center gap-1">
            <Image className="w-3 h-3" /> صور CP (ارفع صور لتحل محل الرسومات الافتراضية)
          </h4>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {cpImageKeys.map(item => (
              <div key={item.key} className="bg-[#161618] rounded-lg p-3 border border-white/5">
                <label className="block text-[10px] text-slate-400 font-bold mb-1.5">{item.label}</label>
                {cpImages[item.key] ? (
                  <div className="relative mb-2">
                    <img src={cpImages[item.key]} className="w-full h-20 object-contain rounded-lg bg-black/30"
                      onError={e => { (e.target as HTMLImageElement).src = ''; }} />
                    <button onClick={() => updateImage(item.key, '')}
                      className="absolute -top-2 -right-2 w-5 h-5 rounded-full bg-rose-500 text-white text-[10px]">×</button>
                  </div>
                ) : (
                  <div className="w-full h-20 rounded-lg bg-black/10 border border-dashed border-white/5 flex items-center justify-center text-[9px] text-slate-600 mb-2">
                    {item.default}
                  </div>
                )}
                <div className="flex gap-1">
                  <label className="flex items-center justify-center gap-1 text-[9px] px-2 py-1 rounded border border-white/10 hover:bg-white/5 cursor-pointer flex-1">
                    <Upload className="w-2.5 h-2.5" />
                    رفع
                    <input type="file" accept="image/*,.svg" onChange={async e => {
                      const file = e.target.files?.[0]; if (!file) return;
                      const url = await uploadToCloudinary(file, 'cp');
                      updateImage(item.key, url);
                    }} className="hidden" />
                  </label>
                </div>
                <input type="text" value={cpImages[item.key] || ''}
                  onChange={e => updateImage(item.key, e.target.value)}
                  placeholder="أو ألصق رابط..." className="w-full mt-1 bg-[#161618] border border-white/10 rounded py-1 px-2 text-[9px] text-white font-mono" />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
