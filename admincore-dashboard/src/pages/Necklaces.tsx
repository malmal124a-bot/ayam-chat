import { useEffect, useState } from 'react';
import { NecklaceConfig } from '../types';
import { getNecklaces, updateNecklace, deleteNecklace } from '../lib/db';
import { uploadStoreItem } from '../lib/storage';
import DataTable from '../components/DataTable';
import ImageUpload from '../components/ImageUpload';
import { Save, X, Plus, Trash2 } from 'lucide-react';

export default function NecklacesPage() {
  const [necklaces, setNecklaces] = useState<NecklaceConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<NecklaceConfig | null>(null);
  const [isAdding, setIsAdding] = useState(false);
  const [form, setForm] = useState({ name: '', name_ar: '', name_en: '', description_ar: '', description_en: '', svgaUrl: '', imageUrl: '', price: 0, sortOrder: 0, isActive: true, type: '' as '' | 'event' | 'admin' | 'recharge', requiredRechargeLevel: 0 });
  const [msg, setMsg] = useState('');

  const showMsg = (t: string) => { setMsg(t); setTimeout(() => setMsg(''), 3000); };

  useEffect(() => { getNecklaces().then(d => { setNecklaces(d); setLoading(false); }); }, []);

  const resetForm = () => { setForm({ name: '', name_ar: '', name_en: '', description_ar: '', description_en: '', svgaUrl: '', imageUrl: '', price: 0, sortOrder: 0, isActive: true, type: '', requiredRechargeLevel: 0 }); setIsAdding(false); };

  const handleEdit = (n: NecklaceConfig) => {
    setEditing(n);
    setIsAdding(false);
    setForm({
      name: n.name_ar || n.name, name_ar: n.name_ar || '', name_en: n.name_en || '',
      description_ar: n.description_ar || '', description_en: n.description_en || '',
      svgaUrl: n.svgaUrl || '',
      imageUrl: n.imageUrl || '',
      price: n.price || 0,
      sortOrder: n.sortOrder || 0, isActive: n.isActive ?? true,
      type: n.type || '',
      requiredRechargeLevel: n.requiredRechargeLevel || 0,
    });
  };

  const handleSave = async () => {
    if (!editing) return;
    try {
      await updateNecklace(editing.id, { ...form, svgaUrl: form.svgaUrl || null, imageUrl: form.imageUrl || null, type: form.type || null, requiredRechargeLevel: form.type === 'recharge' ? form.requiredRechargeLevel : 0 });
      setEditing(null);
      resetForm();
      setNecklaces(await getNecklaces());
      showMsg('Saved!');
    } catch (err) {
      alert('فشل الحفظ: ' + (err as Error).message);
    }
  };
  const handleAdd = () => {
    setEditing(null);
    setIsAdding(true);
    setForm({ name: '', name_ar: '', name_en: '', description_ar: '', description_en: '', svgaUrl: '', imageUrl: '', price: 0, sortOrder: necklaces.length, isActive: true, type: '', requiredRechargeLevel: 0 });
  };
  const handleAddSave = async () => {
    if (!form.name_ar.trim() && !form.name_en.trim()) {
      showMsg('Please enter a name');
      return;
    }
    try {
      const id = 'necklace_' + Date.now();
      await updateNecklace(id, { id, ...form, svgaUrl: form.svgaUrl || null, imageUrl: form.imageUrl || null, type: form.type || null, requiredRechargeLevel: form.type === 'recharge' ? form.requiredRechargeLevel : 0 });
      setEditing(null);
      resetForm();
      setNecklaces(await getNecklaces());
      showMsg('Added!');
    } catch (err) {
      alert('فشل الإضافة: ' + (err as Error).message);
    }
  };

  const handleDelete = async (n: NecklaceConfig) => {
    if (!confirm(`Delete ${n.name}?`)) return;
    await deleteNecklace(n.id);
    setNecklaces(prev => prev.filter(i => i.id !== n.id));
    showMsg('Deleted!');
  };

  const getTypeLabel = (type?: string) => {
    switch (type) {
      case 'event': return '🎪 Event';
      case 'admin': return '🛠️ Admin';
      case 'recharge': return '💰 Recharge';
      default: return 'General';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">Necklace Management</h2>
          <p className="text-slate-500 text-xs mt-0.5">{necklaces.length} necklaces</p>
        </div>
        <button onClick={handleAdd} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
          <Plus className="w-3.5 h-3.5" /> Add Necklace
        </button>
      </div>
      {msg && <div className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs px-4 py-2 rounded-lg">{msg}</div>}

      {(editing || isAdding) && (
        <div className="bg-[#141417] rounded-2xl border border-indigo-500/20 p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-white font-semibold text-sm">{editing ? 'Editing: ' + editing.name : 'New Necklace'}</h3>
            <button onClick={() => { setEditing(null); resetForm(); }} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Name (Arabic)</label>
              <input value={form.name_ar} onChange={e => setForm(p => ({ ...p, name_ar: e.target.value }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Name (English)</label>
              <input value={form.name_en} onChange={e => setForm(p => ({ ...p, name_en: e.target.value }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div className="col-span-2">
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Description (Arabic)</label>
              <textarea value={form.description_ar} onChange={e => setForm(p => ({ ...p, description_ar: e.target.value }))} rows={2} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div className="col-span-2">
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Description (English)</label>
              <textarea value={form.description_en} onChange={e => setForm(p => ({ ...p, description_en: e.target.value }))} rows={2} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Type</label>
              <select value={form.type} onChange={e => setForm(p => ({ ...p, type: e.target.value as any }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white">
                <option value="">Select Type</option>
                <option value="event">🎪 Event</option>
                <option value="admin">🛠️ Admin</option>
                <option value="recharge">💰 Recharge</option>
              </select>
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Price</label>
              <input type="number" value={form.price} onChange={e => setForm(p => ({ ...p, price: Number(e.target.value) }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Sort Order</label>
              <input type="number" value={form.sortOrder} onChange={e => setForm(p => ({ ...p, sortOrder: Number(e.target.value) }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Active</label>
              <label className="flex items-center gap-2 mt-2">
                <input type="checkbox" checked={form.isActive} onChange={e => setForm(p => ({ ...p, isActive: e.target.checked }))} className="w-4 h-4" />
                <span className="text-xs text-slate-400">{form.isActive ? 'Enabled' : 'Disabled'}</span>
              </label>
            </div>
            {form.type === 'recharge' && (
              <div>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Required Recharge Level</label>
                <input type="number" value={form.requiredRechargeLevel} onChange={e => setForm(p => ({ ...p, requiredRechargeLevel: Number(e.target.value) }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
              </div>
            )}
          </div>
          <div className="grid grid-cols-2 gap-4">
            <ImageUpload
              currentUrl={form.svgaUrl}
              onUpload={file => uploadStoreItem(file, 'necklace_svga')}
              onUrlChange={url => setForm(p => ({ ...p, svgaUrl: url }))}
              label="SVGA Model"
              accept=".svga,.webp,.png,.mp4,.vap"
            />
            <ImageUpload
              currentUrl={form.imageUrl}
              onUpload={file => uploadStoreItem(file, 'necklace_img')}
              onUrlChange={url => setForm(p => ({ ...p, imageUrl: url }))}
              label="Preview Image"
              accept=".webp,.png,.jpg"
            />
          </div>
          <div className="flex gap-2">
            <button onClick={editing ? handleSave : handleAddSave} className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
              <Save className="w-3 h-3" /> {editing ? 'Save' : 'Create'}
            </button>
          </div>
        </div>
      )}

      <DataTable
        loading={loading}
        columns={[
          { key: 'imageUrl', label: 'Preview', width: '60px', render: (n: NecklaceConfig) =>
            n.imageUrl ? <img src={n.imageUrl} className="w-8 h-8 object-contain rounded" /> :
            n.svgaUrl ? <img src={n.svgaUrl} className="w-8 h-8 object-contain rounded" /> :
            <div className="w-8 h-8 rounded bg-slate-800" />
          },
          { key: 'name', label: 'Name', sortable: true },
          { key: 'type', label: 'Type', sortable: true, render: (n: NecklaceConfig) => <span className="text-xs">{getTypeLabel(n.type)}</span> },
          { key: 'price', label: 'Price', sortable: true },
          { key: 'sortOrder', label: 'Order', sortable: true },
          {
            key: 'actions', label: '', width: '60px',
            render: (n: NecklaceConfig) => (
              <button onClick={() => handleDelete(n)} className="text-rose-400 hover:text-rose-300">
                <Trash2 className="w-4 h-4" />
              </button>
            ),
          },
        ]}
        data={necklaces}
        onEdit={handleEdit}
        searchKeys={['name']}
      />
    </div>
  );
}
