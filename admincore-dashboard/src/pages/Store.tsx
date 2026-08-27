import { useEffect, useMemo, useRef, useState, type ChangeEvent } from 'react';
import { deleteStoreItem, listStoreItems, upsertStoreItem } from '../lib/api';
import { uploadToCloudinary } from '../lib/cloudinary';
import { supabase } from '../lib/supabase';
import { STORE_TYPES, type StoreItemRow, type StoreItemType } from '../lib/types';
import {
  Badge,
  Field,
  FullSpinner,
  Modal,
  PageHeader,
  SearchBox,
  Toggle,
  useToast,
} from '../lib/ui';

const TYPE_BADGE: Record<string, string> = {
  gift: 'gold',
  frame: 'purple',
  entryEffect: 'blue',
  fancyId: 'gray',
};

const emptyForm = {
  id: '',
  name: '',
  category: '',
  item_type: 'frame' as StoreItemType,
  price: 100,
  min_level: 1,
  animated: true,
  is_active: true,
  order: 0,
  image_url: '',
  svga_url: '',
};

export default function Store() {
  const [rows, setRows] = useState<StoreItemRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [form, setForm] = useState<typeof emptyForm | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState('');
  const fileRef = useRef<HTMLInputElement>(null);
  const toast = useToast();

  const load = () => {
    listStoreItems()
      .then(setRows)
      .catch((e) => toast.push(e.message, 'err'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    const sub = supabase
      .channel('dashboard-store')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'store_items' }, () => load())
      .subscribe();
    return () => {
      supabase.removeChannel(sub);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return rows.filter((r) => {
      // Exclude gifts from this page - gifts are managed in the Gifts page
      if (r.item_type === 'gift') return false;
      if (typeFilter !== 'all' && r.item_type !== typeFilter) return false;
      if (q && !r.name.toLowerCase().includes(q) && !r.id.toLowerCase().includes(q)) return false;
      return true;
    });
  }, [rows, query, typeFilter]);

  const handleFile = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file || !form) return;
    setUploading(file.name);
    try {
      const url = await uploadToCloudinary(file, { folder: 'ayam_store' });
      const isSvga = /\.svga$/i.test(file.name);
      if (isSvga) {
        setForm({ ...form, svga_url: url, animated: true });
        toast.push('تم رفع ملف الأنيميشن');
      } else {
        setForm({ ...form, image_url: url });
        toast.push('تم رفع الصورة');
      }
    } catch (err: any) {
      toast.push(err.message || 'فشل الرفع', 'err');
    } finally {
      setUploading('');
    }
  };

  const save = async () => {
    if (!form) return;
    setSaving(true);
    try {
      const isNew = !form.id;
      await upsertStoreItem({
        id: form.id || undefined,
        name: form.name,
        category: form.item_type === 'gift' ? form.category : '',
        item_type: form.item_type,
        price: Number(form.price),
        min_level: Number(form.min_level),
        animated: form.animated,
        is_active: form.is_active,
        order: Number(form.order),
        image_url: form.image_url || null,
        svga_url: form.svga_url || null,
      });
      toast.push(isNew ? 'تمت إضافة العنصر إلى متجر التطبيق' : 'تم تحديث العنصر');
      setForm(null);
      load();
    } catch (e: any) {
      toast.push(e.message, 'err');
    } finally {
      setSaving(false);
    }
  };

  const remove = async (r: StoreItemRow) => {
    if (!confirm(`حذف ${r.name} من المتجر؟ سيختفي فورًا من التطبيق.`)) return;
    try {
      await deleteStoreItem(r.id);
      toast.push('تم الحذف');
      load();
    } catch (e: any) {
      toast.push(e.message, 'err');
    }
  };

  const openEdit = (r: StoreItemRow) => {
    setForm({
      id: r.id,
      name: r.name,
      category: r.category || 'شائعة',
      item_type: r.item_type,
      price: Number(r.price ?? 0),
      min_level: Number(r.min_level ?? 0),
      animated: r.animated,
      is_active: r.is_active,
      order: Number(r.order ?? 0),
      image_url: r.image_url || '',
      svga_url: r.svga_url || '',
    });
  };

  if (loading) return <FullSpinner />;

  return (
    <div>
      <PageHeader
        title="المتجر (الإطارات والدخوليات)"
        subtitle="الإطارات والدخوليات والرموز المميزة — تظهر في قسم المتجر بالتطبيق"
        actions={
          <button
            className="btn btn-gold"
            onClick={() => setForm({ ...emptyForm })}
          >
            + إضافة عنصر جديد
          </button>
        }
      />

      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <SearchBox value={query} onChange={setQuery} placeholder="بحث بالاسم / الكود..." />
        <select className="select" style={{ maxWidth: 180 }} value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)}>
          <option value="all">كل الأنواع</option>
          <option value="frame">إطارات</option>
          <option value="entryEffect">دخوليات</option>
          <option value="fancyId">رموز مميزة</option>
        </select>
        <span className="badge badge-blue">{filtered.length} عنصر</span>
      </div>

      <div className="table-wrap">
        <table className="rt">
          <thead>
            <tr>
              <th>العنصر</th>
              <th>الصورة</th>
              <th>النوع</th>
              <th>القسم</th>
              <th>السعر 💎</th>
              <th>المستوى</th>
              <th>أنيميشن</th>
              <th>مفعّل</th>
              <th>إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((r) => (
              <tr key={r.id}>
                <td>
                  <div style={{ fontWeight: 700 }}>{r.name}</div>
                  <div style={{ color: 'var(--muted)', fontSize: 11, direction: 'ltr', textAlign: 'right' }}>{r.id}</div>
                </td>
                <td>
                  {r.image_url ? (
                    <img
                      src={r.image_url}
                      alt=""
                      style={{ width: 40, height: 40, borderRadius: 10, objectFit: 'cover', background: '#243350' }}
                      onError={(e) => ((e.target as HTMLImageElement).style.display = 'none')}
                    />
                  ) : (
                    <span style={{ color: 'var(--muted)' }}>—</span>
                  )}
                </td>
                <td>
                  <Badge kind={TYPE_BADGE[r.item_type] || 'gray'}>{STORE_TYPES.find((t) => t.value === r.item_type)?.label || r.item_type}</Badge>
                </td>
                <td>{r.category || '—'}</td>
                <td style={{ fontWeight: 800, color: 'var(--gold)' }}>{r.price}</td>
                <td>{r.min_level}</td>
                <td>{r.animated ? <Badge kind="purple">متصل ✓</Badge> : <Badge kind="gray">لا</Badge>}</td>
                <td>
                  <Toggle
                    checked={r.is_active}
                    onChange={async (v) => {
                      try {
                        await upsertStoreItem({ id: r.id, is_active: v });
                        setRows((prev) => prev.map((x) => (x.id === r.id ? { ...x, is_active: v } : x)));
                        toast.push(v ? 'تم التفعيل في التطبيق' : 'تم إخفاء العنصر من التطبيق');
                      } catch (e: any) {
                        toast.push(e.message, 'err');
                      }
                    }}
                  />
                </td>
                <td>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button className="btn btn-ghost" style={{ padding: '5px 10px', fontSize: 12 }} onClick={() => openEdit(r)}>
                      تعديل
                    </button>
                    <button className="btn btn-danger" style={{ padding: '5px 10px', fontSize: 12 }} onClick={() => remove(r)}>
                      حذف
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {form && (
        <Modal title={form.id ? `تعديل: ${form.name}` : 'إضافة عنصر جديد للمتجر'} onClose={() => setForm(null)} wide>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 14px' }}>
            <Field label="الاسم (يظهر للمستخدمين)">
              <input className="input" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
            </Field>
            <Field label="الكود (سيكون منشئًا تلقائيًا إذا تُرك فارغًا)">
              <input className="input" dir="ltr" value={form.id} onChange={(e) => setForm({ ...form, id: e.target.value })} />
            </Field>
            <Field label="النوع">
              <select className="select" value={form.item_type} onChange={(e) => setForm({ ...form, item_type: e.target.value as StoreItemType })}>
                <option value="frame">إطار</option>
                <option value="entryEffect">دخولية</option>
                <option value="fancyId">رمز مميز</option>
              </select>
            </Field>
            <Field label="السعر (الماس)">
              <input className="input" type="number" value={form.price} onChange={(e) => setForm({ ...form, price: Number(e.target.value) })} />
            </Field>
            <Field label="الحد الأدنى للمستوى">
              <input className="input" type="number" value={form.min_level} onChange={(e) => setForm({ ...form, min_level: Number(e.target.value) })} />
            </Field>
            <Field label="الترتيب">
              <input className="input" type="number" value={form.order} onChange={(e) => setForm({ ...form, order: Number(e.target.value) })} />
            </Field>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, paddingTop: 8 }}>
              <Toggle checked={form.animated} onChange={(v) => setForm({ ...form, animated: v })} />
              <span style={{ color: 'var(--muted)' }}>أنيميشن SVGA</span>
            </div>
          </div>

          <div style={{ marginTop: 16, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
            <div className="card" style={{ padding: 16, borderColor: 'var(--line)' }}>
              <div style={{ fontWeight: 800, marginBottom: 10, fontSize: 14 }}>🖼️ صورة الهدية</div>
              {form.image_url ? (
                <img
                  src={form.image_url}
                  alt=""
                  style={{ width: 90, height: 90, borderRadius: 12, objectFit: 'cover', marginBottom: 10, display: 'block', background: '#243350' }}
                  onError={(e) => ((e.target as HTMLImageElement).style.display = 'none')}
                />
              ) : (
                <p style={{ color: 'var(--muted)', fontSize: 12 }}>لم يتم رفع صورة</p>
              )}
              <button className="btn btn-ghost" style={{ fontSize: 12 }} onClick={() => fileRef.current?.click()} disabled={!!uploading}>
                {uploading ? 'جاري الرفع...' : 'رفع صورة إلى Cloudinary'}
              </button>
            </div>

            <div className="card" style={{ padding: 16, borderColor: 'var(--line)' }}>
              <div style={{ fontWeight: 800, marginBottom: 10, fontSize: 14 }}>🎬 ملف الأنيميشن (SVGA)</div>
              {form.svga_url ? (
                <div style={{ fontSize: 12, color: 'var(--green)', marginBottom: 10, wordBreak: 'break-all' }}>✓ {form.svga_url}</div>
              ) : (
                <p style={{ color: 'var(--muted)', fontSize: 12 }}>لم يتم رفع ملف SVGA</p>
              )}
              <button className="btn btn-ghost" style={{ fontSize: 12 }} onClick={() => fileRef.current?.click()} disabled={!!uploading}>
                {uploading ? 'جاري الرفع...' : 'رفع ملف SVGA'}
              </button>
            </div>
          </div>
          <input ref={fileRef} type="file" accept="image/*,.svga,.gif" hidden onChange={handleFile} />

          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 16 }}>
            <Toggle checked={form.is_active} onChange={(v) => setForm({ ...form, is_active: v })} />
            <span style={{ color: 'var(--muted)' }}>ظاهر في التطبيق</span>
          </div>

          <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
            <button className="btn btn-gold" onClick={save} disabled={saving || !!uploading}>
              {saving ? '...' : 'حفظ ونشر في التطبيق'}
            </button>
            <button className="btn btn-ghost" onClick={() => setForm(null)}>
              إلغاء
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
