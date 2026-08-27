import { useEffect, useState } from 'react';
import { AppConfig } from '../types';
import { getAppConfig, updateAppConfig } from '../lib/db';
import { uploadToCloudinary } from '../lib/storage';
import { to6Hex } from '../lib/colors';
import { Save, Upload, RotateCcw } from 'lucide-react';

export default function ProfileCustomizePage() {
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

  const resetSection = (prefix: string) => {
    const defaults: Record<string, any> = {
      profile_header_height: 220,
      profile_header_overlay: true,
      profile_show_badges: true,
      profile_show_gift_album: true,
      profile_show_chat_room: true,
      profile_card_radius: 12,
      profile_avatar_size: 100,
    };
    const updates: Record<string, any> = {};
    Object.keys(config).forEach(k => {
      if (k.startsWith(prefix) && defaults[k] !== undefined) {
        updates[k] = defaults[k];
      }
    });
    setConfig(p => ({ ...p, ...updates }));
  };

  const handleUpload = async (field: string, e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const url = await uploadToCloudinary(file, 'profile');
    setConfig(p => ({ ...p, [field]: url }));
  };

  if (loading) return <div className="text-slate-500 text-xs">Loading...</div>;

  return (
    <div className="space-y-6 max-w-3xl">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">Profile Page Settings</h2>
          <p className="text-slate-500 text-xs mt-0.5">Customize the user profile page appearance</p>
        </div>
        <button onClick={handleSave} disabled={saving} className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 disabled:bg-indigo-800 text-white text-xs font-medium px-4 py-2 rounded-lg transition-all">
          <Save className="w-4 h-4" />
          {saving ? 'Saving...' : 'Save All'}
        </button>
      </div>

      {/* Header Section */}
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-white text-sm font-semibold">Header Background</h3>
          <button onClick={() => resetSection('profile_header')} className="text-[10px] text-slate-500 hover:text-white flex items-center gap-1">
            <RotateCcw className="w-3 h-3" /> Reset
          </button>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Header Height (px)</label>
            <input type="number" value={(config as any).profile_header_height ?? 220} onChange={e => setConfig(p => ({ ...p, profile_header_height: Number(e.target.value) || 220 }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white" />
          </div>
          <div>
            <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Border Radius</label>
            <input type="number" value={(config as any).profile_card_radius ?? 12} onChange={e => setConfig(p => ({ ...p, profile_card_radius: Number(e.target.value) || 12 }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white" />
          </div>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Gradient Start Color</label>
            <div className="flex gap-2 items-center">
              <input type="color" value={to6Hex(((config as any).profile_header_gradient_start as string) || '#6366F1')} onChange={e => setConfig(p => ({ ...p, profile_header_gradient_start: e.target.value }))} className="w-10 h-10 rounded cursor-pointer bg-transparent border border-white/10 shrink-0" />
              <input type="text" value={(config as any).profile_header_gradient_start || ''} onChange={e => setConfig(p => ({ ...p, profile_header_gradient_start: e.target.value }))} className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono" />
            </div>
          </div>
          <div>
            <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Gradient End Color</label>
            <div className="flex gap-2 items-center">
              <input type="color" value={to6Hex(((config as any).profile_header_gradient_end as string) || '#4F46E5')} onChange={e => setConfig(p => ({ ...p, profile_header_gradient_end: e.target.value }))} className="w-10 h-10 rounded cursor-pointer bg-transparent border border-white/10 shrink-0" />
              <input type="text" value={(config as any).profile_header_gradient_end || ''} onChange={e => setConfig(p => ({ ...p, profile_header_gradient_end: e.target.value }))} className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono" />
            </div>
          </div>
        </div>
        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Header Background Image</label>
          <div className="flex items-center gap-4">
            {(config as any).profile_header_bg ? (
              <div className="relative">
                <img src={(config as any).profile_header_bg} className="w-32 h-20 object-cover rounded-lg border border-white/5" />
                <button onClick={() => setConfig(p => ({ ...p, profile_header_bg: '' }))} className="absolute -top-2 -right-2 w-5 h-5 rounded-full bg-rose-500 text-white text-[10px]">×</button>
              </div>
            ) : (
              <label className="w-32 h-20 rounded-lg border-2 border-dashed border-white/10 flex flex-col items-center justify-center cursor-pointer hover:border-indigo-500/50 transition-all">
                <Upload className="w-5 h-5 text-slate-500 mb-1" />
                <span className="text-[9px] text-slate-600">Upload</span>
                <input type="file" accept="image/*" onChange={(e) => handleUpload('profile_header_bg', e)} className="hidden" />
              </label>
            )}
          </div>
          <input type="text" value={(config as any).profile_header_bg || ''} onChange={e => setConfig(p => ({ ...p, profile_header_bg: e.target.value }))} placeholder="Or paste URL..." className="w-full mt-2 bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white font-mono" />
        </div>
        <div className="flex items-center gap-3">
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" checked={(config as any).profile_header_overlay !== false} onChange={e => setConfig(p => ({ ...p, profile_header_overlay: e.target.checked }))} className="rounded border-white/10 bg-[#161618]" />
            <span className="text-[11px] text-slate-300">Show overlay gradient</span>
          </label>
        </div>
      </div>

      {/* Sections Visibility */}
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
        <h3 className="text-white text-sm font-semibold">Section Visibility</h3>
        <div className="space-y-3">
          {[
            { key: 'profile_show_badges', label: 'Badges Section' },
            { key: 'profile_show_gift_album', label: 'Gift Album (Badge Wall)' },
            { key: 'profile_show_chat_room', label: 'Chat Room Card' },
          ].map(({ key, label }) => (
            <label key={key} className="flex items-center gap-3 cursor-pointer">
              <input type="checkbox" checked={(config as any)[key] !== false} onChange={e => setConfig(p => ({ ...p, [key]: e.target.checked }))} className="rounded border-white/10 bg-[#161618]" />
              <span className="text-xs text-slate-300">{label}</span>
            </label>
          ))}
        </div>
      </div>

      {/* Avatar Settings */}
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-white text-sm font-semibold">Avatar Settings</h3>
          <button onClick={() => resetSection('profile_avatar')} className="text-[10px] text-slate-500 hover:text-white flex items-center gap-1">
            <RotateCcw className="w-3 h-3" /> Reset
          </button>
        </div>
        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">Avatar Size (px)</label>
          <input type="number" value={(config as any).profile_avatar_size ?? 100} onChange={e => setConfig(p => ({ ...p, profile_avatar_size: Number(e.target.value) || 100 }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white" />
        </div>
      </div>

      {/* Add profile images from the Android assets */}
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
        <h3 className="text-white text-sm font-semibold">Profile Images</h3>
        <p className="text-[10px] text-slate-500">Upload images from the Android profile assets to override defaults</p>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
          <ImageUploadField label="Default Background" field="profile_default_bg" config={config} onUpdate={setConfig} onUpload={(f) => handleUpload('profile_default_bg', f)} />
        </div>
      </div>
    </div>
  );
}

function ImageUploadField({ label, field, config, onUpdate, onUpload }: {
  label: string;
  field: string;
  config: AppConfig;
  onUpdate: (updater: (prev: AppConfig) => AppConfig) => void;
  onUpload: (e: React.ChangeEvent<HTMLInputElement>) => void;
}) {
  return (
    <div>
      <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">{label}</label>
      {(config as any)[field] ? (
        <div className="relative">
          <img src={(config as any)[field]} className="w-full h-24 object-cover rounded-lg border border-white/5" />
          <button onClick={() => onUpdate(p => ({ ...p, [field]: '' }))} className="absolute -top-2 -right-2 w-5 h-5 rounded-full bg-rose-500 text-white text-[10px]">×</button>
        </div>
      ) : (
        <label className="w-full h-24 rounded-lg border-2 border-dashed border-white/10 flex flex-col items-center justify-center cursor-pointer hover:border-indigo-500/50 transition-all">
          <Upload className="w-5 h-5 text-slate-500 mb-1" />
          <span className="text-[9px] text-slate-600">Upload</span>
          <input type="file" accept="image/*" onChange={onUpload} className="hidden" />
        </label>
      )}
    </div>
  );
}
