import { useEffect, useState, useContext } from 'react';
import { I18nContext } from '../lib/i18n';
import { getSigninRewards, upsertSigninReward, updateSigninReward, deleteSigninReward } from '../lib/db';
import { uploadAppAsset } from '../lib/storage';
import type { SigninRewardModel } from '../types';
import DataTable from '../components/DataTable';
import ImageUpload from '../components/ImageUpload';
import { Plus, Save, X, Calendar, Trash2 } from 'lucide-react';

const defaultForm = {
  id: '',
  day_number: 1,
  label_ar: '',
  label_en: '',
  icon_url: '',
  svga_url: '',
  value: 100,
  value_type: 'coins',
  gift_id: '',
  is_double: false,
  is_active: true,
};

const valueTypes = [
  { key: 'coins', labelAr: 'عملات', labelEn: 'Coins' },
  { key: 'diamonds', labelAr: 'ماس', labelEn: 'Diamonds' },
  { key: 'xp', labelAr: 'نقاط خبرة', labelEn: 'XP' },
  { key: 'gift', labelAr: 'هدية (عنصر)', labelEn: 'Gift (Item)' },
  { key: 'custom', labelAr: 'مخصص', labelEn: 'Custom' },
];

export default function SigninFeaturesPage() {
  const { lang } = useContext(I18nContext);
  const isAr = lang === 'ar';

  const [rewards, setRewards] = useState<SigninRewardModel[]>([]);
  const [form, setForm] = useState({ ...defaultForm });
  const [editingId, setEditingId] = useState<string | null>(null);
  const [showAdd, setShowAdd] = useState(false);
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState('');

  const showMsg = (m: string) => {
    setMsg(m);
    setTimeout(() => setMsg(''), 3000);
  };

  const load = () => {
    getSigninRewards().then(r => setRewards(r)).catch(e => console.warn('load signin rewards error:', e)).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const resetForm = () => { setForm({ ...defaultForm }); setEditingId(null); setShowAdd(false); };

  const updateForm = (field: string, value: any) => setForm(p => ({ ...p, [field]: value }));

  const handleEdit = (r: SigninRewardModel) => {
    setEditingId(r.id);
    setShowAdd(false);
    setForm({
      id: r.id,
      day_number: r.day_number,
      label_ar: r.label_ar || '',
      label_en: r.label_en || '',
      icon_url: r.icon_url || '',
      svga_url: r.svga_url || '',
      value: r.value ?? 0,
      value_type: r.value_type || 'coins',
      gift_id: r.gift_id || '',
      is_double: r.is_double,
      is_active: r.is_active,
    });
  };

  const handleSave = async () => {
    if (!editingId) return;
    if (!form.label_ar) { showMsg(isAr ? 'أدخل الاسم العربي' : 'Enter Arabic label'); return; }
    await updateSigninReward(editingId, { ...form, gift_id: form.gift_id || null } as any);
    resetForm();
    load();
    showMsg(isAr ? 'تم الحفظ' : 'Saved!');
  };

  const handleAdd = async () => {
    if (!form.label_ar) { showMsg(isAr ? 'أدخل الاسم العربي' : 'Enter Arabic label'); return; }
    const id = 'signin_day_' + form.day_number;
    await upsertSigninReward(id, { ...form, id, gift_id: form.gift_id || null } as any);
    resetForm();
    load();
    showMsg(isAr ? 'تمت الإضافة' : 'Added!');
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-white text-lg font-semibold">{isAr ? '📅 المكافآت اليومية' : '📅 Weekly Sign-In Rewards'}</h2>
      </div>

      {msg && <div className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs px-4 py-2 rounded-lg">{msg}</div>}

      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <p className="text-slate-500 text-xs">{rewards.length} {isAr ? 'مكافأة (7 أيام)' : 'rewards (7 days)'}</p>
          <button onClick={() => { resetForm(); setShowAdd(!showAdd); }}
            className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
            <Plus className="w-3.5 h-3.5" /> {showAdd ? (isAr ? 'إلغاء' : 'Cancel') : (isAr ? 'إضافة مكافأة' : 'Add Reward')}
          </button>
        </div>

        {(editingId || showAdd) && (
          <div className="bg-[#141417] rounded-2xl border border-indigo-500/20 p-6 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-white font-semibold text-sm">
                {editingId ? (isAr ? 'تعديل مكافأة اليوم ' : 'Edit Day ') + form.day_number : (isAr ? 'مكافأة جديدة' : 'New Reward')}
              </h3>
              <button onClick={resetForm} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
            </div>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <div>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{isAr ? 'رقم اليوم (1-7)' : 'Day Number (1-7)'}</label>
                <input type="number" min={1} max={7} value={form.day_number}
                  onChange={e => updateForm('day_number', Math.min(7, Math.max(1, Number(e.target.value) || 1)))}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
              </div>
              <div>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{isAr ? 'الاسم (عربي)' : 'Label (Arabic)'}</label>
                <input value={form.label_ar} onChange={e => updateForm('label_ar', e.target.value)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
              </div>
              <div>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{isAr ? 'الاسم (إنجليزي)' : 'Label (English)'}</label>
                <input value={form.label_en} onChange={e => updateForm('label_en', e.target.value)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
              </div>
              <div>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{isAr ? 'القيمة' : 'Value'}</label>
                <input type="number" min={0} value={form.value} onChange={e => updateForm('value', Number(e.target.value) || 0)} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
              </div>
              <div>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{isAr ? 'نوع المكافأة' : 'Reward Type'}</label>
                <select value={form.value_type} onChange={e => updateForm('value_type', e.target.value)}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white">
                  {valueTypes.map(t => <option key={t.key} value={t.key}>{isAr ? t.labelAr : t.labelEn}</option>)}
                </select>
              </div>
              {form.value_type === 'gift' && (
                <div>
                  <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Gift ID</label>
                  <input value={form.gift_id} onChange={e => updateForm('gift_id', e.target.value)} placeholder="item_id" className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
                </div>
              )}
              <div>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{isAr ? 'مضاعف' : 'Double Reward'}</label>
                <label className="flex items-center gap-2 mt-1">
                  <input type="checkbox" checked={form.is_double} onChange={e => updateForm('is_double', e.target.checked)} className="w-4 h-4" />
                  <span className="text-xs text-slate-400">{isAr ? 'مضاعف (نجمة)' : 'Double (star)'}</span>
                </label>
              </div>
              <div>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{isAr ? 'نشط' : 'Active'}</label>
                <label className="flex items-center gap-2 mt-1">
                  <input type="checkbox" checked={form.is_active} onChange={e => updateForm('is_active', e.target.checked)} className="w-4 h-4" />
                  <span className="text-xs text-slate-400">{form.is_active ? (isAr ? 'مفعل' : 'Enabled') : (isAr ? 'معطل' : 'Disabled')}</span>
                </label>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <ImageUpload currentUrl={form.icon_url} onUpload={file => uploadAppAsset(file, `signin_icon_${Date.now()}`)} onUrlChange={url => updateForm('icon_url', url)} label={isAr ? 'أيقونة المكافأة (PNG/WebP)' : 'Reward Icon (PNG/WebP)'} accept="image/*,.webp,.png,.svg" />
              <ImageUpload currentUrl={form.svga_url} onUpload={file => uploadAppAsset(file, `signin_svga_${Date.now()}`)} onUrlChange={url => updateForm('svga_url', url)} label={isAr ? 'ملف الأنميشن (SVGA)' : 'Animation (SVGA)'} accept=".svga,.zip,.mp4,.vap" />
            </div>
            <button onClick={editingId ? handleSave : handleAdd} className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
              <Save className="w-3 h-3" /> {editingId ? (isAr ? 'حفظ' : 'Save') : (isAr ? 'إضافة' : 'Add')}
            </button>
          </div>
        )}

        <DataTable loading={loading} searchKeys={['label_ar', 'label_en']}
          columns={[
            { key: 'day_number', label: isAr ? 'اليوم' : 'Day', sortable: true },
            { key: 'icon_url', label: '', render: (r: SigninRewardModel) => r.icon_url ? <img src={r.icon_url} className="w-8 h-8 object-contain rounded" /> : <div className="w-8 h-8 rounded bg-slate-800 flex items-center justify-center text-lg">🎁</div> },
            { key: 'label_ar', label: isAr ? 'الاسم' : 'Name', sortable: true },
            { key: 'value', label: isAr ? 'القيمة' : 'Value', sortable: true, render: (r: SigninRewardModel) => <span>{r.value} {r.is_double && <span className="text-amber-400 ml-1">★</span>}</span> },
            { key: 'value_type', label: isAr ? 'النوع' : 'Type', render: (r: SigninRewardModel) => <span className="text-indigo-300">{valueTypes.find(t => t.key === r.value_type) ? (isAr ? valueTypes.find(t => t.key === r.value_type)!.labelAr : valueTypes.find(t => t.key === r.value_type)!.labelEn) : r.value_type}</span> },
            { key: 'is_active', label: isAr ? 'نشط' : 'Active', render: (r: SigninRewardModel) => <span className={r.is_active ? 'text-emerald-400' : 'text-rose-400'}>{r.is_active ? (isAr ? 'نعم' : 'Yes') : (isAr ? 'لا' : 'No')}</span> },
          ]}
          data={rewards} onEdit={handleEdit} onDelete={async (r) => { if (confirm(isAr ? `حذف مكافأة اليوم ${r.day_number}؟` : `Delete day ${r.day_number} reward?`)) { await deleteSigninReward(r.id); load(); } }} />
      </div>
    </div>
  );
}
