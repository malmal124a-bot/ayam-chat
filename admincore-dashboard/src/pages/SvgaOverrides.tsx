import { useEffect, useState, useRef } from 'react';
import { supabase } from '../lib/supabase';
import { uploadToCloudinary } from '../lib/cloudinary';
import {
  Badge,
  FullSpinner,
  Modal,
  PageHeader,
  SearchBox,
  Field,
  useToast,
} from '../lib/ui';

interface SvgaAsset {
  id: string;
  local_path: string;
  remote_url: string;
  display_name: string;
  preview_image_url: string;
  category: string;
  created_at: string;
}

const CATEGORIES = [
  { value: 'gift', label: 'هدايا', color: 'gold' },
  { value: 'entry_effect', label: 'تأثيرات دخول', color: 'purple' },
  { value: 'rocket', label: 'صاروخ / كرستال', color: 'blue' },
  { value: 'vip_frame', label: 'إطارات VIP', color: 'green' },
  { value: 'badge', label: 'شارات', color: 'pink' },
  { value: 'other', label: 'أخرى', color: 'gray' },
];

const getCategoryInfo = (v: string) => CATEGORIES.find((c) => c.value === v) || CATEGORIES[5];

export default function SvgaOverrides() {
  const [rows, setRows] = useState<SvgaAsset[]>([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState('');
  const [catFilter, setCatFilter] = useState('all');
  const [form, setForm] = useState<Partial<SvgaAsset> | null>(null);
  const [saving, setSaving] = useState(false);
  const [uploadingSvga, setUploadingSvga] = useState(false);
  const [uploadingImg, setUploadingImg] = useState(false);
  const toast = useToast();

  const load = async () => {
    try {
      const { data, error } = await supabase
        .from('svga_url_overrides')
        .select('*')
        .order('category')
        .order('display_name');
      if (error) throw error;
      setRows(data || []);
    } catch (e: any) {
      toast.push(e.message, 'err');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const filtered = rows.filter((r) => {
    if (catFilter !== 'all' && r.category !== catFilter) return false;
    if (query) {
      const q = query.toLowerCase();
      return (
        (r.display_name || '').toLowerCase().includes(q) ||
        r.local_path.toLowerCase().includes(q) ||
        (r.remote_url || '').toLowerCase().includes(q)
      );
    }
    return true;
  });

  const openAdd = () => setForm({
    local_path: '',
    remote_url: '',
    display_name: '',
    preview_image_url: '',
    category: 'gift',
  });

  const openEdit = (r: SvgaAsset) => setForm({ ...r });

  const handleSvgaUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !form) return;
    setUploadingSvga(true);
    try {
      const url = await uploadToCloudinary(file, {
        folder: 'svga_assets/svga',
        resourceType: 'raw',
      });
      setForm((prev) => ({
        ...prev,
        remote_url: url,
        local_path: prev?.local_path || `assets/svga/${file.name}`,
      }));
      toast.push('تم رفع ملف SVGA بنجاح');
    } catch (err: any) {
      toast.push('فشل رفع SVGA: ' + err.message, 'err');
    } finally {
      setUploadingSvga(false);
      e.target.value = '';
    }
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !form) return;
    setUploadingImg(true);
    try {
      const url = await uploadToCloudinary(file, {
        folder: 'svga_assets/preview',
        resourceType: 'image',
      });
      setForm((prev) => ({ ...prev, preview_image_url: url }));
      toast.push('تم رفع صورة المعاينة بنجاح');
    } catch (err: any) {
      toast.push('فشل رفع الصورة: ' + err.message, 'err');
    } finally {
      setUploadingImg(false);
      e.target.value = '';
    }
  };

  const save = async () => {
    if (!form?.remote_url || !form?.local_path) {
      toast.push('يجب رفع ملف SVGA أولاً', 'err');
      return;
    }
    setSaving(true);
    try {
      const payload = {
        local_path: form.local_path,
        remote_url: form.remote_url,
        display_name: form.display_name || '',
        preview_image_url: form.preview_image_url || '',
        category: form.category || 'gift',
        updated_at: new Date().toISOString(),
      };
      const { error } = await supabase
        .from('svga_url_overrides')
        .upsert(payload, { onConflict: 'local_path' });
      if (error) throw error;
      toast.push('تم الحفظ بنجاح');
      setForm(null);
      load();
    } catch (e: any) {
      toast.push('خطأ: ' + e.message, 'err');
    } finally {
      setSaving(false);
    }
  };

  const remove = async (r: SvgaAsset) => {
    if (!confirm(`حذف "${r.display_name || r.local_path}"؟`)) return;
    try {
      const { error } = await supabase
        .from('svga_url_overrides')
        .delete()
        .eq('id', r.id);
      if (error) throw error;
      toast.push('تم الحذف');
      load();
    } catch (e: any) {
      toast.push('خطأ: ' + e.message, 'err');
    }
  };

  const stats = {
    total: rows.length,
    gifts: rows.filter((r) => r.category === 'gift').length,
    effects: rows.filter((r) => r.category === 'entry_effect').length,
    rockets: rows.filter((r) => r.category === 'rocket').length,
  };

  if (loading) return <FullSpinner />;

  return (
    <div>
      <PageHeader
        title="إدارة ملفات SVGA"
        subtitle={`${stats.total} ملف — هدايا: ${stats.gifts} | تأثيرات: ${stats.effects} | صواريخ: ${stats.rockets}`}
        actions={
          <button className="btn primary" onClick={openAdd}>+ إضافة ملف SVGA جديد</button>
        }
      />

      <div className="toolbar" style={{ marginBottom: 16, display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <SearchBox value={query} onChange={setQuery} placeholder="بحث بالاسم أو المسار..." />
        <select
          value={catFilter}
          onChange={(e) => setCatFilter(e.target.value)}
          style={{
            background: '#1a1a2e', border: '1px solid #333', borderRadius: 8,
            padding: '8px 14px', color: '#fff', fontSize: 13,
          }}
        >
          <option value="all">الكل ({stats.total})</option>
          {CATEGORIES.map((c) => (
            <option key={c.value} value={c.value}>{c.label} ({rows.filter((r) => r.category === c.value).length})</option>
          ))}
        </select>
      </div>

      {/* Grid of existing assets */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 14, marginBottom: 24 }}>
        {filtered.map((r) => {
          const cat = getCategoryInfo(r.category);
          return (
            <div
              key={r.id}
              style={{
                background: '#1a1a2e',
                borderRadius: 14,
                border: '1px solid #333',
                overflow: 'hidden',
              }}
            >
              {/* Preview image or placeholder */}
              <div style={{
                height: 140,
                background: '#111',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                position: 'relative',
                overflow: 'hidden',
              }}>
                {r.preview_image_url ? (
                  <img
                    src={r.preview_image_url}
                    alt={r.display_name}
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                ) : (
                  <div style={{ textAlign: 'center', color: '#555' }}>
                    <div style={{ fontSize: 32 }}>🎬</div>
                    <div style={{ fontSize: 11, marginTop: 4 }}>لا توجد صورة معاينة</div>
                  </div>
                )}
                <div style={{
                  position: 'absolute', top: 8, left: 8,
                  background: 'rgba(0,0,0,0.7)', borderRadius: 6,
                  padding: '3px 8px', fontSize: 11,
                }}>
                  <Badge kind={cat.color}>{cat.label}</Badge>
                </div>
              </div>

              {/* Info */}
              <div style={{ padding: 12 }}>
                <div style={{ fontWeight: 700, fontSize: 14, marginBottom: 4 }}>
                  {r.display_name || 'بدون اسم'}
                </div>
                <div style={{ fontSize: 10, color: '#888', fontFamily: 'monospace', wordBreak: 'break-all', marginBottom: 8, lineHeight: 1.4 }}>
                  {r.local_path}
                </div>
                {r.remote_url && (
                  <div style={{
                    fontSize: 10, color: '#4CAF50', marginBottom: 10,
                    overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                  }}>
                    ✓ Cloudinary
                  </div>
                )}

                {/* Actions */}
                <div style={{ display: 'flex', gap: 6 }}>
                  <button className="btn sm" onClick={() => openEdit(r)} style={{ flex: 1 }}>تعديل</button>
                  <button className="btn sm danger" onClick={() => remove(r)}>حذف</button>
                </div>
              </div>
            </div>
          );
        })}
        {filtered.length === 0 && (
          <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: 40, color: '#666' }}>
            لا توجد ملفات — اضغط "+ إضافة ملف SVGA جديد" للبدء
          </div>
        )}
      </div>

      {/* Add/Edit Modal */}
      {form && (
        <Modal onClose={() => setForm(null)} title={form.id ? 'تعديل ملف SVGA' : 'إضافة ملف SVGA جديد'} wide>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
            {/* Left: SVGA file */}
            <div>
              <Field label="1. ملف SVGA (الرسوم المتحركة)">
                <div style={{
                  border: '2px dashed #444', borderRadius: 12, padding: 20,
                  textAlign: 'center', background: '#111',
                }}>
                  {form.remote_url ? (
                    <div>
                      <div style={{ color: '#4CAF50', fontSize: 14, fontWeight: 700, marginBottom: 4 }}>
                        ✓ تم رفع ملف SVGA
                      </div>
                      <div style={{ fontSize: 10, color: '#888', wordBreak: 'break-all' }}>
                        {form.remote_url.substring(0, 60)}...
                      </div>
                    </div>
                  ) : (
                    <div style={{ color: '#666' }}>
                      <div style={{ fontSize: 28, marginBottom: 6 }}>📁</div>
                      <div style={{ fontSize: 13 }}>اسحب ملف SVGA هنا أو اضغط للاختيار</div>
                    </div>
                  )}
                  <label style={{
                    display: 'inline-block', marginTop: 12,
                    background: '#ffd700', color: '#000', borderRadius: 8,
                    padding: '8px 20px', fontSize: 13, fontWeight: 700,
                    cursor: 'pointer',
                  }}>
                    {uploadingSvga ? 'جاري الرفع...' : form.remote_url ? 'تغيير الملف' : 'اختيار ملف SVGA'}
                    <input
                      type="file"
                      accept=".svga,.vap,.mp4,.json"
                      style={{ display: 'none' }}
                      disabled={uploadingSvga}
                      onChange={handleSvgaUpload}
                    />
                  </label>
                </div>
              </Field>

              <Field label="2. صورة المعاينة (اختياري)">
                <div style={{
                  border: '2px dashed #444', borderRadius: 12, padding: 16,
                  textAlign: 'center', background: '#111',
                }}>
                  {form.preview_image_url ? (
                    <div style={{ position: 'relative' }}>
                      <img
                        src={form.preview_image_url}
                        alt="preview"
                        style={{ width: '100%', maxHeight: 120, objectFit: 'contain', borderRadius: 8 }}
                      />
                      <button
                        onClick={() => setForm((p) => p ? { ...p, preview_image_url: '' } : null)}
                        style={{
                          position: 'absolute', top: 4, right: 4,
                          background: 'rgba(0,0,0,0.7)', color: '#ff6b6b',
                          border: 'none', borderRadius: 6, padding: '2px 8px',
                          fontSize: 11, cursor: 'pointer',
                        }}
                      >
                        ✕
                      </button>
                    </div>
                  ) : (
                    <div style={{ color: '#666', fontSize: 12 }}>صورة المعاينة التي تظهر في التطبيق</div>
                  )}
                  <label style={{
                    display: 'inline-block', marginTop: 10,
                    background: '#333', color: '#fff', borderRadius: 8,
                    padding: '6px 16px', fontSize: 12, fontWeight: 600,
                    cursor: 'pointer',
                  }}>
                    {uploadingImg ? 'جاري الرفع...' : 'اختيار صورة'}
                    <input
                      type="file"
                      accept="image/*"
                      style={{ display: 'none' }}
                      disabled={uploadingImg}
                      onChange={handleImageUpload}
                    />
                  </label>
                </div>
              </Field>
            </div>

            {/* Right: Details */}
            <div>
              <Field label="اسم العرض (الاسم الذي يظهر للمستخدم)">
                <input
                  className="input"
                  value={form.display_name || ''}
                  onChange={(e) => setForm({ ...form, display_name: e.target.value })}
                  placeholder="مثال: أسد الفخامة، وردة الحب..."
                />
              </Field>

              <Field label="المسار المحلي (local_path في الكود)">
                <input
                  className="input"
                  value={form.local_path || ''}
                  onChange={(e) => setForm({ ...form, local_path: e.target.value })}
                  placeholder="assets/gifts/my_gift.svga"
                  style={{ fontFamily: 'monospace', fontSize: 12 }}
                />
              </Field>

              <Field label="القسم في التطبيق">
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
                  {CATEGORIES.map((c) => (
                    <button
                      key={c.value}
                      onClick={() => setForm({ ...form, category: c.value })}
                      style={{
                        padding: '8px 12px',
                        borderRadius: 8,
                        border: form.category === c.value ? '2px solid var(--gold)' : '2px solid #333',
                        background: form.category === c.value ? 'rgba(255,215,0,0.1)' : '#1a1a2e',
                        color: form.category === c.value ? '#ffd700' : '#aaa',
                        fontSize: 12,
                        fontWeight: form.category === c.value ? 700 : 400,
                        cursor: 'pointer',
                        textAlign: 'center',
                      }}
                    >
                      {c.label}
                    </button>
                  ))}
                </div>
              </Field>

              {/* Preview */}
              <div style={{
                marginTop: 16, padding: 12, borderRadius: 10,
                background: '#111', border: '1px solid #333',
              }}>
                <div style={{ fontSize: 11, color: '#888', marginBottom: 8 }}>معاينة:</div>
                <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                  {form.preview_image_url ? (
                    <img
                      src={form.preview_image_url}
                      style={{ width: 48, height: 48, borderRadius: 8, objectFit: 'cover' }}
                    />
                  ) : (
                    <div style={{
                      width: 48, height: 48, borderRadius: 8,
                      background: '#222', display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: 20,
                    }}>
                      🎬
                    </div>
                  )}
                  <div>
                    <div style={{ fontWeight: 700, fontSize: 13 }}>{form.display_name || 'بدون اسم'}</div>
                    <Badge kind={getCategoryInfo(form.category || 'gift').color}>
                      {getCategoryInfo(form.category || 'gift').label}
                    </Badge>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="modal-actions" style={{ marginTop: 20 }}>
            <button className="btn" onClick={() => setForm(null)}>إلغاء</button>
            <button
              className="btn primary"
              onClick={save}
              disabled={saving || !form.remote_url}
            >
              {saving ? 'جاري الحفظ...' : 'حفظ'}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
