import { useEffect, useState, useContext } from 'react';
import { GiftModel, GiftCategory } from '../types';
import { getGifts, getGiftCategories, deleteGift, updateGift, addGift } from '../lib/db';
import { uploadGiftIcon, uploadGiftAnimation } from '../lib/storage';
import DataTable from '../components/DataTable';
import ImageUpload from '../components/ImageUpload';
import { Plus, Save, X } from 'lucide-react';
import { I18nContext } from '../lib/i18n';

export default function GiftsPage() {
  const [gifts, setGifts] = useState<GiftModel[]>([]);
  const [categories, setCategories] = useState<GiftCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<GiftModel | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const [form, setForm] = useState({
    id: '', name: '', value: 0, iconAsset: '', animationAsset: '',
    isVap: false, isLucky: false, isStar: false, isMusic: false,
    packageCount: 0, sortOrder: 0, categoryId: '',
    nameKey: '', photoKey: '', defaultImage: '',
    isCpGift: false, cpGiftDurationHours: 0,
  });
  const { t } = useContext(I18nContext);

  const load = async () => {
    const [d, cats] = await Promise.all([getGifts(), getGiftCategories()]);
    setGifts(d); setCategories(cats); setLoading(false);
  };
  useEffect(() => { load(); }, []);

  const resetForm = () => setForm({ id: '', name: '', value: 0, iconAsset: '', animationAsset: '', isVap: false, isLucky: false, isStar: false, isMusic: false, packageCount: 0, sortOrder: 0, categoryId: '', nameKey: '', photoKey: '', defaultImage: '', isCpGift: false, cpGiftDurationHours: 0 });

  const handleEdit = (g: GiftModel) => {
    setEditing(g);
    setForm({ id: g.id, name: g.name, value: g.value, iconAsset: g.iconAsset, animationAsset: g.animationAsset || '', isVap: g.isVap, isLucky: g.isLucky, isStar: g.isStar, isMusic: g.isMusic, packageCount: g.packageCount, sortOrder: g.sortOrder, categoryId: g.categoryId || '', nameKey: g.nameKey || '', photoKey: g.photoKey || '', defaultImage: g.defaultImage || '', isCpGift: g.isCpGift || false, cpGiftDurationHours: g.cpGiftDurationHours || 0 });
    setShowAdd(false);
  };

  const handleSave = async () => {
    if (!editing) return;
    await updateGift(editing.id, { ...form, categoryId: form.categoryId || null, animationAsset: form.animationAsset || null, nameKey: form.nameKey || null, photoKey: form.photoKey || null, defaultImage: form.defaultImage || null });
    setEditing(null);
    resetForm();
    load();
  };

  const handleAdd = async () => {
    const id = `gift_${Date.now()}`;
    await addGift(id, { ...form, id, categoryId: form.categoryId || null, animationAsset: form.animationAsset || null, nameKey: form.nameKey || null, photoKey: form.photoKey || null, defaultImage: form.defaultImage || null });
    setShowAdd(false);
    resetForm();
    load();
  };

  const handleDelete = async (g: GiftModel) => {
    if (confirm(`Delete gift "${g.name}"?`)) await deleteGift(g.id);
    load();
  };

  const updateField = (field: string, value: unknown) => setForm(p => ({ ...p, [field]: value }));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">{t('gift.management')}</h2>
          <p className="text-slate-500 text-xs mt-0.5">{gifts.length} {t('gift.count')}</p>
        </div>
        <button onClick={() => { setShowAdd(!showAdd); setEditing(null); resetForm(); }} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
          <Plus className="w-3.5 h-3.5" /> {showAdd ? t('cancel') : t('gift.add')}
        </button>
      </div>

      {(editing || showAdd) && (
        <div className="bg-[#141417] rounded-2xl border border-indigo-500/20 p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-white font-semibold text-sm">{editing ? `${t('gift.edit')}: ${editing.name}` : t('gift.new')}</h3>
            <button onClick={() => { setEditing(null); setShowAdd(false); }} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <ImageUpload
              currentUrl={form.iconAsset}
              onUpload={file => uploadGiftIcon(file, form.id || `new_${Date.now()}`)}
              onUrlChange={url => updateField('iconAsset', url)}
              label={t('upload')}
            />
            <ImageUpload
              currentUrl={form.animationAsset}
              onUpload={file => uploadGiftAnimation(file, form.id || `new_${Date.now()}`)}
              onUrlChange={url => updateField('animationAsset', url)}
              label="Animation (SVGA)"
              accept=".svga,.json,.zip,.mp4,.vap"
            />
            {(['name', 'value', 'packageCount', 'sortOrder'] as const).map(f => (
              <div key={f}>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{f}</label>
                <input type={['value', 'packageCount', 'sortOrder'].includes(f) ? 'number' : 'text'} value={form[f]} onChange={e => updateField(f, ['value', 'packageCount', 'sortOrder'].includes(f) ? Number(e.target.value) : e.target.value)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
              </div>
            ))}
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Category</label>
              <select value={form.categoryId} onChange={e => updateField('categoryId', e.target.value)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white">
                <option value="">-- No category --</option>
                {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>
            {form.animationAsset && (
              <>
                <div>
                  <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Name Key</label>
                  <input type="text" value={form.nameKey} onChange={e => updateField('nameKey', e.target.value)} placeholder="e.g. txt_name" className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
                </div>
                <div>
                  <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Photo Key</label>
                  <input type="text" value={form.photoKey} onChange={e => updateField('photoKey', e.target.value)} placeholder="e.g. img_avatar" className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
                </div>
                <div>
                  <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Default Image URL</label>
                  <input type="text" value={form.defaultImage} onChange={e => updateField('defaultImage', e.target.value)} placeholder="Fallback if user has no photo" className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
                </div>
              </>
            )}
          </div>
          <div className="flex items-center gap-4">
            {(['isVap', 'isLucky', 'isStar', 'isMusic'] as const).map(f => (
              <label key={f} className="flex items-center gap-1.5 text-xs text-slate-400">
                <input type="checkbox" checked={form[f]} onChange={e => updateField(f, e.target.checked)} className="accent-indigo-500" />
                {f.replace('is', '')}
              </label>
            ))}
            <label className="flex items-center gap-1.5 text-xs text-rose-400 font-semibold">
              <input type="checkbox" checked={form.isCpGift} onChange={e => updateField('isCpGift', e.target.checked)} className="accent-rose-500" />
              CP Gift
            </label>
            {form.isCpGift && (
              <div className="flex items-center gap-1.5">
                <label className="text-[10px] uppercase text-slate-400 font-bold">Duration (hrs)</label>
                <input type="number" min={0} value={form.cpGiftDurationHours} onChange={e => updateField('cpGiftDurationHours', Number(e.target.value))} className="w-20 bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
              </div>
            )}
          </div>
          <div className="flex gap-2">
            <button onClick={editing ? handleSave : handleAdd} className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
              <Save className="w-3 h-3" /> {editing ? t('save') : t('gift.add')}
            </button>
          </div>
        </div>
      )}

      <DataTable
        loading={loading}
        columns={[
          { key: 'iconAsset', label: '', width: '40px', render: g => g.iconAsset ? <img src={g.iconAsset} className="w-6 h-6 object-contain" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} /> : <div className="w-6 h-6 rounded bg-slate-800" /> },
          { key: 'name', label: t('gift.name'), sortable: true },
          { key: 'categoryId', label: 'Category', render: g => { const cat = categories.find(c => c.id === g.categoryId); return <span className="text-[10px] text-slate-400">{cat ? cat.name : '-'}</span>; } },
          { key: 'value', label: t('gift.value'), sortable: true, render: g => <span className="text-amber-400 font-mono">{g.value}</span> },
          { key: 'isLucky', label: '★', render: g => g.isLucky ? <span className="text-rose-400">✓</span> : '-' },
          { key: 'isStar', label: '☆', render: g => g.isStar ? <span className="text-amber-400">✓</span> : '-' },
          { key: 'isVap', label: 'VAP', render: g => g.isVap ? <span className="text-indigo-400">✓</span> : '-' },
          { key: 'isMusic', label: '♪', render: g => g.isMusic ? <span className="text-emerald-400">✓</span> : '-' },
          { key: 'isCpGift', label: 'CP', render: g => g.isCpGift ? <span className="text-rose-400 font-semibold">♥ {g.cpGiftDurationHours ? `${Math.round(g.cpGiftDurationHours / 24)}d` : ''}</span> : '-' },
          { key: 'sortOrder', label: 'Order', sortable: true },
        ]}
        data={gifts}
        searchKeys={['name', 'id']}
        onEdit={handleEdit}
        onDelete={handleDelete}
      />
    </div>
  );
}
