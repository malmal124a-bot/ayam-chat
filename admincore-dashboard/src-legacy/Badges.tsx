import { useEffect, useState } from 'react';
import { BadgeConfig, LevelConfig } from '../types';
import { getBadges, deleteBadge, updateBadge, addBadge, getLevels } from '../lib/db';
import { uploadBadgeIcon, uploadBadgeSvga } from '../lib/storage';
import DataTable from '../components/DataTable';
import ImageUpload from '../components/ImageUpload';
import { Plus, Save, X, Award } from 'lucide-react';

export default function BadgesPage() {
  const [badges, setBadges] = useState<BadgeConfig[]>([]);
  const [levels, setLevels] = useState<LevelConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<BadgeConfig | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const [form, setForm] = useState({
    id: '', name: '', name_ar: '', name_en: '', description: '', description_ar: '', description_en: '',
    iconAsset: '', imageUrl: '', svgaUrl: '',
    unlockCondition: '', sortOrder: 0, isActive: true,
    type: '' as '' | 'admin' | 'level',
    levelType: '' as '' | 'wealth' | 'recharge' | 'gems', levelNumber: 0,
  });

  const load = async () => {
    const [d, l] = await Promise.all([getBadges(), getLevels()]);
    setBadges(d);
    setLevels(l);
    setLoading(false);
  };
  useEffect(() => { load(); }, []);

  const resetForm = () => setForm({
    id: '', name: '', name_ar: '', name_en: '', description: '', description_ar: '', description_en: '',
    iconAsset: '', imageUrl: '', svgaUrl: '', unlockCondition: '',
    sortOrder: 0, isActive: true, type: '', levelType: '', levelNumber: 0,
  });

  const handleEdit = (b: BadgeConfig) => {
    setEditing(b);
    setForm({
      id: b.id,
      name: b.name_ar || b.name, name_ar: b.name_ar || '', name_en: b.name_en || '',
      description: b.description, description_ar: b.description_ar || '', description_en: b.description_en || '',
      iconAsset: b.iconAsset || '', imageUrl: b.imageUrl || '',
      svgaUrl: b.svgaUrl || '',
      unlockCondition: b.unlockCondition || '',
      sortOrder: b.sortOrder || 0, isActive: b.isActive ?? true,
      type: b.type || '',
      levelType: b.levelType || '',
      levelNumber: b.levelNumber || 0,
    });
    setShowAdd(false);
  };

  const handleSave = async () => {
    if (!editing) return;
    try {
      await updateBadge(editing.id, { ...form, iconAsset: form.iconAsset || null, svgaUrl: form.svgaUrl || null });
      setEditing(null);
      resetForm();
      load();
    } catch (e) {
      alert('Failed to save badge: ' + (e as Error).message);
    }
  };

  const handleAdd = async () => {
    if (!form.name_ar && !form.name_en) {
      alert('Please enter a name');
      return;
    }
    try {
      const id = 'badge_' + Date.now();
      await addBadge(id, { ...form, id, iconAsset: form.iconAsset || null, svgaUrl: form.svgaUrl || null });
      setShowAdd(false);
      resetForm();
      load();
    } catch (e) {
      alert('Failed to add badge: ' + (e as Error).message);
    }
  };

  const handleDelete = async (b: BadgeConfig) => {
    if (confirm(`Delete badge "${b.name}"?`)) await deleteBadge(b.id);
    load();
  };

  const updateField = (field: string, value: unknown) => setForm(p => ({ ...p, [field]: value }));

  const getTypeLabel = (type?: string) => {
    switch (type) {
      case 'admin': return '🛠️ Admin Gift';
      case 'level': return '📈 Level Reward';
      default: return 'General';
    }
  };

  const getLevelLabel = (levelType?: string, levelNumber?: number) => {
    if (!levelType || !levelNumber) return '';
    const typeLabel = levelType.charAt(0).toUpperCase() + levelType.slice(1);
    return `${typeLabel} Lv. ${levelNumber}`;
  };

  const availableLevels = form.levelType ? levels.filter(l => l.type === form.levelType) : [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">Badge Management</h2>
          <p className="text-slate-500 text-xs mt-0.5">{badges.length} badges</p>
        </div>
        <button onClick={() => { setShowAdd(!showAdd); setEditing(null); resetForm(); }} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
          <Plus className="w-3.5 h-3.5" /> {showAdd ? 'Cancel' : 'Add Badge'}
        </button>
      </div>

      {(editing || showAdd) && (
        <div className="bg-[#141417] rounded-2xl border border-indigo-500/20 p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-white font-semibold text-sm">{editing ? 'Editing: ' + editing.name : 'New Badge'}</h3>
            <button onClick={() => { setEditing(null); setShowAdd(false); }} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <ImageUpload
              currentUrl={form.iconAsset}
              onUpload={file => uploadBadgeSvga(file, form.id || 'new_' + Date.now())}
              onUrlChange={url => { updateField('iconAsset', url); updateField('svgaUrl', url); }}
              label="Badge File (SVGA/Zip) - MAIN"
              accept=".svga,.zip,.mp4,.vap"
            />
            <ImageUpload
              currentUrl={form.imageUrl}
              onUpload={file => uploadBadgeIcon(file, form.id || 'new_' + Date.now())}
              onUrlChange={url => updateField('imageUrl', url)}
              label="Badge Preview (PNG/JPG/WebP) - Optional"
              accept=".webp,.png,.jpg,.jpeg"
            />
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Type</label>
              <select
                value={form.type}
                onChange={e => updateField('type', e.target.value as any)}
                className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
              >
                <option value="">Select Type</option>
                <option value="admin">🛠️ Admin Gift</option>
                <option value="level">📈 Level Reward</option>
              </select>
            </div>
            {form.type === 'level' && (
              <>
                <div>
                  <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Level Type</label>
                  <select
                    value={form.levelType}
                    onChange={e => updateField('levelType', e.target.value as any)}
                    className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
                  >
                    <option value="">Select Level Type</option>
                    <option value="wealth">Wealth</option>
                    <option value="recharge">Recharge</option>
                    <option value="gems">Gems</option>
                  </select>
                </div>
                <div>
                  <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Level Number</label>
                  <select
                    value={form.levelNumber}
                    onChange={e => updateField('levelNumber', Number(e.target.value))}
                    className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
                  >
                    <option value={0}>Select Level</option>
                    {availableLevels.map(l => <option key={l.level} value={l.level}>{l.title} (Lv. {l.level})</option>)}
                  </select>
                </div>
              </>
            )}
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Name (Arabic)</label>
              <input value={form.name_ar} onChange={e => updateField('name_ar', e.target.value)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Name (English)</label>
              <input value={form.name_en} onChange={e => updateField('name_en', e.target.value)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div className="col-span-2">
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Description (Arabic)</label>
              <textarea value={form.description_ar} onChange={e => updateField('description_ar', e.target.value)} rows={2} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div className="col-span-2">
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Description (English)</label>
              <textarea value={form.description_en} onChange={e => updateField('description_en', e.target.value)} rows={2} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Unlock Condition</label>
              <input value={form.unlockCondition} onChange={e => updateField('unlockCondition', e.target.value)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Sort Order</label>
              <input type="number" value={form.sortOrder} onChange={e => updateField('sortOrder', Number(e.target.value))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Active</label>
              <label className="flex items-center gap-2 mt-1">
                <input type="checkbox" checked={form.isActive} onChange={e => updateField('isActive', e.target.checked)} className="w-4 h-4" />
                <span className="text-xs text-slate-400">{form.isActive ? 'Enabled' : 'Disabled'}</span>
              </label>
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={editing ? handleSave : handleAdd} className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
              <Save className="w-3 h-3" /> {editing ? 'Save' : 'Add Badge'}
            </button>
          </div>
        </div>
      )}

      <DataTable
        loading={loading}
        columns={[
          { key: 'id', label: 'ID', width: '70px', render: b => <span className="font-mono text-[10px] text-slate-400">{b.id}</span> },
          { key: 'name', label: 'Name', sortable: true, render: b => (
            <div className="flex items-center gap-2">
              {b.imageUrl ? <img src={b.imageUrl} className="w-5 h-5 object-contain" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} /> : 
               b.iconAsset ? <span className="text-amber-400 text-lg">🎬</span> :
               <Award className="w-4 h-4 text-amber-400" />}
              <div className="flex flex-col">
                <span>{b.name}</span>
                {b.iconAsset && <span className="text-[8px] text-indigo-400">📦 Has SVGA/Zip File</span>}
              </div>
            </div>
          )},
          { key: 'type', label: 'Type', sortable: true, render: b => <span className="text-xs">{getTypeLabel(b.type)}</span> },
          { key: 'levelType', label: 'Level Info', render: b => (
            <span className="text-xs text-slate-400">{getLevelLabel(b.levelType, b.levelNumber)}</span>
          )},
          { key: 'description', label: 'Description' },
          { key: 'sortOrder', label: 'Order', sortable: true },
        ]}
        data={badges}
        searchKeys={['name', 'id', 'description']}
        onEdit={handleEdit}
        onDelete={handleDelete}
      />
    </div>
  );
}
