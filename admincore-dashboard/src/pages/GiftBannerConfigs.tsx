import { useEffect, useState, useContext } from 'react';
import { GiftBannerConfig, GiftCategory } from '../types';
import { getGiftBannerConfigs, addGiftBannerConfig, updateGiftBannerConfig, deleteGiftBannerConfig, getGiftCategories } from '../lib/db';
import { uploadGiftBannerSvga } from '../lib/storage';
import ImageUpload from '../components/ImageUpload';
import { Plus, Save, X, Trash2 } from 'lucide-react';
import { I18nContext } from '../lib/i18n';

export default function GiftBannerConfigsPage() {
  const [configs, setConfigs] = useState<GiftBannerConfig[]>([]);
  const [categories, setCategories] = useState<GiftCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<GiftBannerConfig | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const [form, setForm] = useState({
    categoryId: '', thresholdCoins: 0, svgaUrl: '',
    userRKey: 'user_r', userLKey: 'user_l', numberKey: 'number', giftKey: 'gift',
    isActive: true,
  });
  const { t } = useContext(I18nContext);

  const load = async () => {
    const [d, cats] = await Promise.all([getGiftBannerConfigs(), getGiftCategories()]);
    setConfigs(d); setCategories(cats); setLoading(false);
  };
  useEffect(() => { load(); }, []);

  const resetForm = () => setForm({
    categoryId: '', thresholdCoins: 0, svgaUrl: '',
    userRKey: 'user_r', userLKey: 'user_l', numberKey: 'number', giftKey: 'gift',
    isActive: true,
  });

  const handleEdit = (c: GiftBannerConfig) => {
    setEditing(c);
    setForm({
      categoryId: c.categoryId || '', thresholdCoins: c.thresholdCoins, svgaUrl: c.svgaUrl,
      userRKey: c.userRKey, userLKey: c.userLKey, numberKey: c.numberKey, giftKey: c.giftKey,
      isActive: c.isActive,
    });
    setShowAdd(false);
  };

  const handleSave = async () => {
    if (!editing) return;
    await updateGiftBannerConfig(editing.id, form);
    setEditing(null); resetForm();
    load();
  };

  const handleDelete = async (c: GiftBannerConfig) => {
    if (confirm(`Delete banner config "${c.id}"?`)) {
      await deleteGiftBannerConfig(c.id);
      load();
    }
  };

  const handleAdd = async () => {
    const id = `gbc_${Date.now()}`;
    await addGiftBannerConfig(id, { id, ...form });
    setShowAdd(false); resetForm();
    load();
  };

  const updateField = (f: string, v: unknown) => setForm(p => ({ ...p, [f]: v }));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">Gift Banner Configs (SVGA Strip)</h2>
          <p className="text-slate-500 text-xs mt-0.5">{configs.length} banner configs</p>
        </div>
        <button onClick={() => { setShowAdd(!showAdd); setEditing(null); resetForm(); }} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
          <Plus className="w-3.5 h-3.5" /> {showAdd ? 'Cancel' : 'Add Config'}
        </button>
      </div>

      {(editing || showAdd) && (
        <div className="bg-[#141417] rounded-2xl border border-indigo-500/20 p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-white font-semibold text-sm">{editing ? `Editing: ${editing.id}` : 'New Banner Config'}</h3>
            <button onClick={() => { setEditing(null); setShowAdd(false); }} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Gift Category</label>
              <select value={form.categoryId} onChange={e => updateField('categoryId', e.target.value)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white">
                <option value="">All Categories</option>
                {categories.map(cat => (
                  <option key={cat.id} value={cat.id}>{cat.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Threshold Coins</label>
              <input type="number" value={form.thresholdCoins} onChange={e => updateField('thresholdCoins', Number(e.target.value))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div className="flex items-end">
              <label className="flex items-center gap-1.5 text-xs text-slate-400 pb-1.5">
                <input type="checkbox" checked={form.isActive} onChange={e => updateField('isActive', e.target.checked)} className="accent-indigo-500" />
                Active
              </label>
            </div>
            <ImageUpload
              currentUrl={form.svgaUrl}
              onUpload={file => uploadGiftBannerSvga(file, editing?.id || `new_${Date.now()}`)}
              onUrlChange={url => updateField('svgaUrl', url)}
              label="SVGA Animation"
              accept=".svga,.json,.zip"
            />
            {['userRKey', 'userLKey', 'numberKey', 'giftKey'].map(k => (
              <div key={k}>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{k}</label>
                <input type="text" value={form[k as keyof typeof form] as string} onChange={e => updateField(k, e.target.value)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
              </div>
            ))}
          </div>
          <div className="flex gap-2">
            <button onClick={editing ? handleSave : handleAdd} className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
              <Save className="w-3 h-3" /> {editing ? 'Save Changes' : 'Add Config'}
            </button>
          </div>
        </div>
      )}

      {loading ? (
        <div className="text-center py-12 text-slate-500 text-xs">Loading...</div>
      ) : configs.length === 0 ? (
        <div className="text-center py-12 text-slate-500 text-xs">No banner configs yet.</div>
      ) : (
        <div className="space-y-3">
          {configs.map(c => (
            <div key={c.id} className="bg-[#141417] rounded-2xl border border-white/5 p-4 flex items-center gap-4 hover:border-white/10 transition-colors">
              {c.svgaUrl ? (
                <div className="w-24 h-14 rounded-lg bg-gradient-to-br from-indigo-500/20 to-purple-500/20 border border-indigo-500/30 flex items-center justify-center text-[10px] text-indigo-400">SVGA</div>
              ) : (
                <div className="w-24 h-14 rounded-lg bg-slate-800 flex items-center justify-center text-[10px] text-slate-600">No File</div>
              )}
              <div className="flex-1 min-w-0">
                  <div className="text-white text-xs font-medium truncate">{c.id}</div>
                  <div className="text-[10px] text-slate-500 mt-1">
                    {c.categoryId ? <span className="text-indigo-400 font-mono">{categories.find(cat => cat.id === c.categoryId)?.name || c.categoryId}</span> : <span className="text-slate-500">All Categories</span>}
                    <span className="mx-1.5">·</span>
                    Threshold: <span className="text-amber-400 font-mono">{c.thresholdCoins}</span> coins
                    <span className={`ml-2 text-[9px] px-1.5 py-0.5 rounded-full ${c.isActive ? 'bg-emerald-500/10 text-emerald-400' : 'bg-slate-500/10 text-slate-500'}`}>{c.isActive ? 'Active' : 'Inactive'}</span>
                  </div>
                  <div className="text-[9px] text-slate-600 mt-0.5">Keys: {c.userRKey}, {c.userLKey}, {c.numberKey}, {c.giftKey}</div>
              </div>
              <div className="flex items-center gap-2">
                <button onClick={() => handleEdit(c)} className="text-[10px] text-indigo-400 hover:text-indigo-300 font-semibold">Edit</button>
                <button onClick={() => handleDelete(c)} className="text-[10px] text-rose-400 hover:text-rose-300 font-semibold"><Trash2 className="w-3 h-3" /></button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
