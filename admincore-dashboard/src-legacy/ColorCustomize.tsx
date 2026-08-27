import { useEffect, useState } from 'react';
import { AppConfig } from '../types';
import { getAppConfig, updateAppConfig } from '../lib/db';
import { Save, Palette, RotateCcw } from 'lucide-react';
import { to6Hex } from '../lib/colors';

const defaultColors = {
  primaryBg: '#FFFFFF',
  textPrimary: '#16151A',
  textSecondary: '#9BA1B6',
  goldColor: '#DE880F',
  buttonColor: '#6366F1',
  buttonTextColor: '#FFFFFF',
  headerColor: '#FFFFFF',
  tabBarColor: '#FFFFFF',
};

export default function ColorCustomizePage() {
  const [config, setConfig] = useState<AppConfig>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getAppConfig().then(data => { if (data) setConfig(data); setLoading(false); });
  }, []);

  const handleSave = async () => {
    await updateAppConfig(config);
    alert('Colors saved! App will use new theme on next load.');
  };

  const resetToDefaults = () => {
    if (confirm('Reset all colors to defaults?')) {
      setConfig(defaultColors);
    }
  };

  const updateColor = (field: string, value: string) => setConfig(p => ({ ...p, [field]: value }));

  const colorFields: { key: string; label: string; default: string }[] = [
    { key: 'primaryBg', label: 'Background', default: '#FFFFFF' },
    { key: 'textPrimary', label: 'Primary Text', default: '#16151A' },
    { key: 'textSecondary', label: 'Secondary Text', default: '#9BA1B6' },
    { key: 'goldColor', label: 'Gold / Accent', default: '#DE880F' },
    { key: 'buttonColor', label: 'Button Color', default: '#6366F1' },
    { key: 'buttonTextColor', label: 'Button Text', default: '#FFFFFF' },
    { key: 'headerColor', label: 'Header Background', default: '#FFFFFF' },
    { key: 'tabBarColor', label: 'Tab Bar Background', default: '#FFFFFF' },
  ];

  if (loading) return <div className="text-slate-500 text-xs">Loading...</div>;

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h2 className="text-white text-lg font-semibold">Color Customization</h2>
        <p className="text-slate-500 text-xs mt-0.5">Customize all app colors. Changes are saved to Firebase and applied on next app load.</p>
      </div>

      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {colorFields.map(({ key, label, default: def }) => (
            <div key={key}>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">{label}</label>
              <div className="flex gap-2 items-center">
                <input
                  type="color"
                  value={to6Hex((config[key as keyof AppConfig] as string) || def)}
                  onChange={e => updateColor(key, e.target.value)}
                  className="w-10 h-10 rounded cursor-pointer bg-transparent border border-white/10 shrink-0"
                />
                <input
                  type="text"
                  value={config[key as keyof AppConfig] as string || def}
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
              <div className="mt-1 flex items-center gap-2">
                <div className="w-full h-2 rounded" style={{ backgroundColor: config[key as keyof AppConfig] as string || def }} />
              </div>
            </div>
          ))}
        </div>

        <div className="flex gap-3 pt-2">
          <button onClick={handleSave} className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1.5">
            <Palette className="w-3.5 h-3.5" /> Save Colors
          </button>
          <button onClick={resetToDefaults} className="px-5 py-2 border border-white/10 text-xs text-slate-400 rounded-lg hover:bg-white/5">
            Reset to Defaults
          </button>
        </div>
      </div>

      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6">
        <h3 className="text-white text-sm font-semibold mb-4">Screen Titles Customization</h3>
        <p className="text-[10px] text-slate-500 mb-4">Customize the title of each screen in the app</p>
        <div className="grid grid-cols-2 gap-3">
          {[
            { key: 'home', label: 'Home' },
            { key: 'rooms', label: 'Rooms' },
            { key: 'store', label: 'Store' },
            { key: 'profile', label: 'Profile' },
            { key: 'gifts', label: 'Gifts' },
            { key: 'ranking', label: 'Ranking' },
            { key: 'unions', label: 'Unions' },
            { key: 'vip', label: 'VIP' },
            { key: 'settings', label: 'Settings' },
            { key: 'chat', label: 'Chat' },
          ].map(({ key, label }) => (
            <div key={key}>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{label}</label>
              <input
                type="text"
                value={config.screenTitles?.[key] || label}
                onChange={e => setConfig(p => ({
                  ...p,
                  screenTitles: { ...(p.screenTitles || {}), [key]: e.target.value },
                }))}
                className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
              />
            </div>
          ))}
        </div>
        <button onClick={handleSave} className="mt-4 px-4 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg">Save Titles</button>
      </div>
    </div>
  );
}
