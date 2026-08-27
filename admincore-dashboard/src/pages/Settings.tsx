import { useContext, useEffect, useState } from 'react';
import { I18nContext, langs } from '../lib/i18n';
import { getCloudinaryStatus, saveCloudinaryConfig } from '../lib/storage';
import { supabase, isAdminConnected, resetAdminClient, SUPABASE_URL } from '../lib/supabase';
import { Save, Crown, Database } from 'lucide-react';

export default function Settings() {
  const { t, lang, setLang } = useContext(I18nContext);
  const [cloudName, setCloudName] = useState('');
  const [apiKey, setApiKey] = useState('');
  const [apiSecret, setApiSecret] = useState('');
  const [saving, setSaving] = useState(false);
  const [vipUrl, setVipUrl] = useState('');
  const [vipSaving, setVipSaving] = useState(false);
  const [supabaseServiceKey, setSupabaseServiceKey] = useState('');
  const [supabaseSaving, setSupabaseSaving] = useState(false);

  useEffect(() => {
    const status = getCloudinaryStatus();
    setCloudName(status.cloudName);
    const raw = localStorage.getItem('cloudinary_config');
    if (raw) {
      try {
        const cfg = JSON.parse(raw);
        setApiKey(cfg.apiKey || '');
        setApiSecret(cfg.apiSecret || '');
      } catch {}
    } else {
      setApiKey(localStorage.getItem('cloudinary_api_key') || '');
      setApiSecret(localStorage.getItem('cloudinary_api_secret') || '');
    }
    const adminCfg = localStorage.getItem('supabase_admin_config');
    if (adminCfg) {
      try {
        const parsed = JSON.parse(adminCfg);
        setSupabaseServiceKey(parsed.serviceRoleKey || '');
      } catch {}
    }
    supabase.from('app_config').select('value').eq('key', 'vip_url').maybeSingle().then(res => {
      if (res?.data?.value) setVipUrl(String(res.data.value));
    });
  }, []);

  const handleSaveCloudinary = () => {
    setSaving(true);
    saveCloudinaryConfig(cloudName, apiKey, apiSecret);
    setSaving(false);
    alert(t('cloudinary.save') + ' ✓');
  };

  const handleSaveVipUrl = async () => {
    setVipSaving(true);
    try {
      const { error } = await supabase.from('app_config').upsert(
        { key: 'vip_url', value: vipUrl },
        { onConflict: 'key' }
      );
      if (error) throw error;
      alert('VIP URL saved ✓');
    } catch (e) {
      alert('Save failed: ' + (e as Error).message);
    }
    setVipSaving(false);
  };

  const status = getCloudinaryStatus();

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h2 className="text-white text-lg font-semibold">{t('settings.title')}</h2>
        <p className="text-slate-500 text-xs mt-0.5">{t('settings.description')}</p>
      </div>

      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-6">
        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-2">Language / اللغة</label>
          <div className="flex gap-2">
            {langs.map(l => (
              <button
                key={l.code}
                onClick={() => setLang(l.code)}
                className={`px-4 py-2 rounded-lg text-xs font-semibold border transition-all ${
                  lang === l.code
                    ? 'bg-indigo-500/10 text-indigo-300 border-indigo-500/20'
                    : 'text-slate-400 border-white/5 hover:bg-white/5 hover:text-white'
                }`}
              >
                {l.label}
              </button>
            ))}
          </div>
          <p className="text-[9px] text-slate-600 mt-1.5">Change dashboard interface language</p>
        </div>

        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-2">VIP URL</label>
          <div className="bg-[#161618] rounded-lg border border-white/5 p-4 space-y-3">
            <p className="text-xs text-slate-400 flex items-center gap-1.5">
              <Crown className="w-3.5 h-3.5 text-amber-400" />
              VIP Web App URL — التطبيق هيفتح الرابط ده في WebView
            </p>
            <input
              type="url"
              value={vipUrl}
              onChange={e => setVipUrl(e.target.value)}
              className="w-full bg-[#1c1c1f] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white font-mono"
              placeholder="https://your-domain.com/vip"
            />
            <button onClick={handleSaveVipUrl} disabled={vipSaving} className="px-3 py-1.5 bg-amber-600 hover:bg-amber-700 disabled:opacity-50 text-[10px] text-white font-semibold rounded-lg flex items-center gap-1">
              <Save className="w-3 h-3" /> {vipSaving ? t('saving') : 'Save VIP URL'}
            </button>
          </div>
        </div>

        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-2 flex items-center gap-1"><Database className="w-3 h-3" /> Supabase Service Role Key</label>
          <div className="bg-[#161618] rounded-lg border border-white/5 p-4 space-y-3">
            <p className="text-xs text-slate-400">
              {isAdminConnected()
                ? <><span className="text-green-400">✓</span> Service role configured — RLS bypass active</>
                : <><span className="text-rose-400">✗</span> Not configured — some features may not show all data</>
              }
            </p>
            <input
              type="password"
              value={supabaseServiceKey}
              onChange={e => setSupabaseServiceKey(e.target.value)}
              className="w-full bg-[#1c1c1f] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white font-mono"
              placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
            />
            <p className="text-[9px] text-slate-600">Paste your Supabase service_role key to bypass RLS and see all users/data</p>
            <button onClick={() => {
              setSupabaseSaving(true);
              localStorage.setItem('supabase_admin_config', JSON.stringify({
                supabaseUrl: SUPABASE_URL,
                serviceRoleKey: supabaseServiceKey,
              }));
              resetAdminClient();
              setSupabaseSaving(false);
              alert('Supabase key saved! Page will refresh to apply changes.');
              setTimeout(() => window.location.reload(), 500);
            }} disabled={supabaseSaving} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-[10px] text-white font-semibold rounded-lg flex items-center gap-1">
              <Save className="w-3 h-3" /> {supabaseSaving ? t('saving') : 'Save Supabase Key'}
            </button>
          </div>
        </div>

        <div>
          <label className="block text-[10px] uppercase text-slate-400 font-bold mb-2">{t('settings.cloudinary')}</label>
          <div className="bg-[#161618] rounded-lg border border-white/5 p-4 space-y-3">
            <p className="text-xs">
              {status.configured
                ? <><span className="text-green-400">✓</span> {lang === 'ar' ? 'مفعل' : 'Active'} ({status.cloudName})</>
                : <><span className="text-rose-400">✗</span> {lang === 'ar' ? 'غير مفعل' : 'Not configured'}</>
              }
            </p>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div>
                <label className="block text-[9px] uppercase text-slate-500 font-bold mb-1">{t('cloudinary.cloudName')}</label>
                <input type="text" value={cloudName} onChange={e => setCloudName(e.target.value)} className="w-full bg-[#1c1c1f] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white font-mono" placeholder="dl30muiuc" />
              </div>
              <div>
                <label className="block text-[9px] uppercase text-slate-500 font-bold mb-1">{t('cloudinary.apiKey')}</label>
                <input type="text" value={apiKey} onChange={e => setApiKey(e.target.value)} className="w-full bg-[#1c1c1f] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white font-mono" placeholder="865669713469485" />
              </div>
              <div>
                <label className="block text-[9px] uppercase text-slate-500 font-bold mb-1">{t('cloudinary.apiSecret')}</label>
                <input type="password" value={apiSecret} onChange={e => setApiSecret(e.target.value)} className="w-full bg-[#1c1c1f] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white font-mono" placeholder="API Secret" />
              </div>
            </div>
            <p className="text-[9px] text-slate-600">{t('cloudinary.description')}</p>
            <button onClick={handleSaveCloudinary} disabled={saving} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-[10px] text-white font-semibold rounded-lg flex items-center gap-1">
              <Save className="w-3 h-3" /> {saving ? t('saving') : t('cloudinary.save')}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
