import { useEffect, useRef, useState, type ChangeEvent } from 'react';
import { deleteBanner, listBanners, upsertBanner } from '../lib/api';
import { uploadToCloudinary } from '../lib/cloudinary';
import { supabase } from '../lib/supabase';
import type { BannerRow } from '../lib/types';
import { FullSpinner, PageHeader, useToast } from '../lib/ui';

export default function Banners() {
  const [rows, setRows] = useState<BannerRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [title, setTitle] = useState('');
  const [order, setOrder] = useState(0);
  const [url, setUrl] = useState('');
  const [busy, setBusy] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);
  const toast = useToast();

  const load = () => {
    listBanners()
      .then(setRows)
      .catch((e) => toast.push(e.message, 'err'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    const sub = supabase
      .channel('dashboard-banners')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'banners' }, () => load())
      .subscribe();
    return () => {
      supabase.removeChannel(sub);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const pick = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file) return;
    setBusy(true);
    try {
      const u = await uploadToCloudinary(file, { folder: 'ayam_banners' });
      setUrl(u);
      toast.push('تم رفع الصورة');
    } catch (err: any) {
      toast.push(err.message || 'فشل الرفع', 'err');
    } finally {
      setBusy(false);
    }
  };

  const add = async () => {
    if (!url) {
      toast.push('ارفع صورة أولاً', 'err');
      return;
    }
    setBusy(true);
    try {
      await upsertBanner({ image_url: url, title: title || null, order: Number(order) });
      toast.push('تمت إضافة البنر');
      setUrl('');
      setTitle('');
      setOrder(rows.length);
      load();
    } catch (e: any) {
      toast.push(e.message, 'err');
    } finally {
      setBusy(false);
    }
  };

  const remove = async (b: BannerRow) => {
    try {
      await deleteBanner(b.id);
      toast.push('تم الحذف');
      load();
    } catch (e: any) {
      toast.push(e.message, 'err');
    }
  };

  if (loading) return <FullSpinner />;

  return (
    <div>
      <PageHeader title="البنرات" subtitle="بنرات الصفحة الرئيسية للغرف — تُعرض في التطبيق" />

      <div className="card" style={{ padding: 20, marginBottom: 18 }}>
        <h3 style={{ margin: '0 0 14px', fontSize: 15, fontWeight: 800, color: 'var(--gold)' }}>إضافة بنر جديد</h3>
        <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'flex-end' }}>
          <div style={{ flex: 1, minWidth: 200 }}>
            <div style={{ marginBottom: 6, color: 'var(--muted)', fontWeight: 700, fontSize: 12 }}>العنوان</div>
            <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="مثال: عرض الصيف" />
          </div>
          <div style={{ width: 110 }}>
            <div style={{ marginBottom: 6, color: 'var(--muted)', fontWeight: 700, fontSize: 12 }}>الترتيب</div>
            <input className="input" type="number" value={order} onChange={(e) => setOrder(Number(e.target.value))} />
          </div>
          <button className="btn btn-ghost" onClick={() => fileRef.current?.click()} disabled={busy}>
            {busy ? '...' : url ? '🔄 تغيير الصورة' : '📤 رفع صورة'}
          </button>
          <button className="btn btn-gold" onClick={add} disabled={busy || !url}>
            حفظ البنر
          </button>
        </div>
        {url && (
          <img
            src={url}
            alt=""
            style={{ marginTop: 14, maxHeight: 90, borderRadius: 12, display: 'block', background: '#243350' }}
            onError={(e) => ((e.target as HTMLImageElement).style.display = 'none')}
          />
        )}
        <input ref={fileRef} type="file" accept="image/*" hidden onChange={pick} />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(260px,1fr))', gap: 16 }}>
        {rows.map((b) => (
          <div key={b.id} className="card" style={{ padding: 14 }}>
            {b.image_url && (
              <img
                src={b.image_url}
                alt=""
                style={{ width: '100%', height: 120, objectFit: 'cover', borderRadius: 12, background: '#243350' }}
                onError={(e) => ((e.target as HTMLImageElement).style.display = 'none')}
              />
            )}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 12 }}>
              <div>
                <div style={{ fontWeight: 800 }}>{b.title || 'بدون عنوان'}</div>
                <div style={{ color: 'var(--muted)', fontSize: 12 }}>الترتيب: {b.order}</div>
              </div>
              <button className="btn btn-danger" style={{ padding: '5px 10px', fontSize: 12 }} onClick={() => remove(b)}>
                حذف
              </button>
            </div>
          </div>
        ))}
        {rows.length === 0 && <p style={{ color: 'var(--muted)' }}>لا بنرات بعد</p>}
      </div>
    </div>
  );
}
