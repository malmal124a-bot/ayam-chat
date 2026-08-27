import { useEffect, useState } from 'react';
import { AppConfig } from '../types';
import { getAppConfig, updateAppConfig } from '../lib/db';
import { Save, Upload } from 'lucide-react';
import { uploadToCloudinary } from '../lib/storage';

export default function ImageCustomizePage() {
  const [config, setConfig] = useState<AppConfig>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    getAppConfig().then(data => { if (data) setConfig(data); setLoading(false); });
  }, []);

  const handleSave = async () => {
    setSaving(true);
    await updateAppConfig(config);
    setSaving(false);
    alert('Saved!');
  };

  const handleUploadSplash = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const url = await uploadToCloudinary(file, 'config');
    setConfig(p => ({ ...p, splashGifUrl: url }));
  };

  if (loading) return <div className="text-slate-500 text-xs">Loading...</div>;

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h2 className="text-white text-lg font-semibold">Image Customization</h2>
        <p className="text-slate-500 text-xs mt-0.5">Configure all app images, splash screen, logos, and banners</p>
      </div>

      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-5">
        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">App Name</label>
          <input type="text" value={config.appName || ''} onChange={e => setConfig(p => ({ ...p, appName: e.target.value }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white" />
          <p className="text-[9px] text-slate-600 mt-1">This changes the app display name across the application</p>
        </div>

        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Splash Screen Image/GIF</label>
          <div className="flex items-center gap-4">
            {config.splashGifUrl ? (
              <div className="relative">
                {config.splashGifUrl.match(/\.(gif|mp4|webm)$/i) ? (
                  <img src={config.splashGifUrl} className="w-32 h-32 object-contain rounded-lg border border-white/5 bg-black/20" />
                ) : (
                  <img src={config.splashGifUrl} className="w-32 h-32 object-contain rounded-lg border border-white/5 bg-black/20" onError={e => { (e.target as HTMLImageElement).src = ''; }} />
                )}
                <button onClick={() => setConfig(p => ({ ...p, splashGifUrl: '' }))} className="absolute -top-2 -right-2 w-5 h-5 rounded-full bg-rose-500 text-white text-[10px]">×</button>
              </div>
            ) : (
              <label className="w-32 h-32 rounded-lg border-2 border-dashed border-white/10 flex flex-col items-center justify-center cursor-pointer hover:border-indigo-500/50 transition-all">
                <Upload className="w-6 h-6 text-slate-500 mb-1" />
                <span className="text-[9px] text-slate-600">Upload</span>
                <input type="file" accept="image/*" onChange={handleUploadSplash} className="hidden" />
              </label>
            )}
          </div>
          <input type="text" value={config.splashGifUrl || ''} onChange={e => setConfig(p => ({ ...p, splashGifUrl: e.target.value }))} placeholder="Or paste URL..." className="w-full mt-2 bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white font-mono" />
        </div>

        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Font Family</label>
          <select value={config.fontFamily || 'system'} onChange={e => setConfig(p => ({ ...p, fontFamily: e.target.value }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white">
            <option value="system">System Default</option>
            <option value="Cairo">Cairo (Arabic)</option>
            <option value="Noto Sans Arabic">Noto Sans Arabic</option>
            <option value="Tajawal">Tajawal</option>
            <option value="Almarai">Almarai</option>
          </select>
        </div>

        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Border Radius</label>
          <input type="range" min="0" max="24" value={Number.isFinite(config.borderRadius) ? config.borderRadius : 8} onChange={e => setConfig(p => ({ ...p, borderRadius: Number(e.target.value) }))} className="w-full accent-indigo-500" />
          <div className="flex justify-between text-[9px] text-slate-600">
            <span>0</span>
            <span className="text-white font-mono">{Number.isFinite(config.borderRadius) ? config.borderRadius : 8}px</span>
            <span>24</span>
          </div>
        </div>

        <button onClick={handleSave} disabled={saving} className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-xs text-white font-semibold rounded-lg flex items-center gap-1.5">
          <Save className="w-3.5 h-3.5" /> {saving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>
    </div>
  );
}
