import { useEffect, useState, useContext } from 'react';
import { GiftCategory } from '../types';
import { getGiftCategories, addGiftCategory, updateGiftCategory, deleteGiftCategory } from '../lib/db';
import { Plus, Save, X, Trash2 } from 'lucide-react';
import { I18nContext } from '../lib/i18n';

export default function GiftCategoriesPage() {
  const [cats, setCats] = useState<GiftCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<GiftCategory | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const [form, setForm] = useState({ name: '', sortOrder: 0 });
  const { t } = useContext(I18nContext);

  const load = async () => { const d = await getGiftCategories(); setCats(d); setLoading(false); };
  useEffect(() => { load(); }, []);

  const resetForm = () => setForm({ name: '', sortOrder: cats.length });

  const handleEdit = (c: GiftCategory) => {
    setEditing(c);
    setForm({ name: c.name, sortOrder: c.sortOrder });
    setShowAdd(false);
  };

  const handleSave = async () => {
    if (!editing) return;
    await updateGiftCategory(editing.id, form);
    setEditing(null); resetForm();
    load();
  };

  const handleDelete = async (c: GiftCategory) => {
    if (confirm(`Delete category "${c.name}"?`)) {
      await deleteGiftCategory(c.id);
      load();
    }
  };

  const handleAdd = async () => {
    const id = `cat_${Date.now()}`;
    await addGiftCategory(id, { id, ...form });
    setShowAdd(false); resetForm();
    load();
  };

  const updateField = (f: string, v: unknown) => setForm(p => ({ ...p, [f]: v }));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">Gift Categories</h2>
          <p className="text-slate-500 text-xs mt-0.5">{cats.length} categories</p>
        </div>
        <button onClick={() => { setShowAdd(!showAdd); setEditing(null); resetForm(); }} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
          <Plus className="w-3.5 h-3.5" /> {showAdd ? 'Cancel' : 'Add Category'}
        </button>
      </div>

      {(editing || showAdd) && (
        <div className="bg-[#141417] rounded-2xl border border-indigo-500/20 p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-white font-semibold text-sm">{editing ? `Editing: ${editing.name}` : 'New Category'}</h3>
            <button onClick={() => { setEditing(null); setShowAdd(false); }} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Name</label>
              <input type="text" value={form.name} onChange={e => updateField('name', e.target.value)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Sort Order</label>
              <input type="number" value={form.sortOrder} onChange={e => updateField('sortOrder', Number(e.target.value))} className="w-20 bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={editing ? handleSave : handleAdd} className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
              <Save className="w-3 h-3" /> {editing ? 'Save Changes' : 'Add Category'}
            </button>
          </div>
        </div>
      )}

      {loading ? (
        <div className="text-center py-12 text-slate-500 text-xs">Loading...</div>
      ) : cats.length === 0 ? (
        <div className="text-center py-12 text-slate-500 text-xs">No categories yet.</div>
      ) : (
        <div className="space-y-3">
          {cats.map(c => (
            <div key={c.id} className="bg-[#141417] rounded-2xl border border-white/5 p-4 flex items-center gap-4 hover:border-white/10 transition-colors">
              <div className="flex-1 min-w-0">
                <div className="text-white text-xs font-medium truncate">{c.name}</div>
                <div className="text-[10px] text-slate-500 mt-1">Order: {c.sortOrder}</div>
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
