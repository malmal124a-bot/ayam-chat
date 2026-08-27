import { useState, useEffect, useRef } from 'react';
import { api } from '../lib/api';

export default function Dashboard({ session, toast }) {
  const [wallet, setWallet] = useState(null);
  const [agency, setAgency] = useState(null);
  const [loading, setLoading] = useState(true);
  const [editingProfile, setEditingProfile] = useState(false);
  const [editName, setEditName] = useState('');
  const [editPhoto, setEditPhoto] = useState('');
  const [savingProfile, setSavingProfile] = useState(false);
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef(null);

  const agencyId = session.agency_id;

  useEffect(() => {
    loadAll();
  }, []);

  const loadAll = async () => {
    setLoading(true);
    try {
      const [w, a] = await Promise.all([
        api(`/api/agency/wallet?agency_id=${agencyId}`).catch(() => null),
        api(`/api/agency/profile?agency_id=${agencyId}`).catch(() => null),
      ]);
      setWallet(w);
      setAgency(a);
      if (a) {
        setEditName(a.name || '');
        setEditPhoto(a.photo_url || '');
      }
    } catch (e) {
      toast('تعذر تحميل البيانات: ' + e.message, 'error');
    } finally {
      setLoading(false);
    }
  };

  const handlePhotoUpload = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith('image/')) {
      toast('يرجى اختيار صورة', 'error');
      return;
    }
    setUploading(true);
    try {
      const reader = new FileReader();
      const base64 = await new Promise((resolve, reject) => {
        reader.onload = () => resolve(reader.result.split(',')[1]);
        reader.onerror = reject;
        reader.readAsDataURL(file);
      });

      const res = await api('/api/agency/upload-photo', {
        method: 'POST',
        body: { agency_id: agencyId, image_base64: base64, filename: file.name },
      });
      if (!res.ok) throw new Error(res.error || 'Upload failed');
      setEditPhoto(res.url);
      toast('تم رفع الصورة بنجاح');
    } catch (err) {
      toast('فشل رفع الصورة: ' + err.message, 'error');
    } finally {
      setUploading(false);
    }
  };

  const handleSaveProfile = async () => {
    if (!editName.trim()) {
      toast('الاسم مطلوب', 'error');
      return;
    }
    setSavingProfile(true);
    try {
      const res = await api('/api/agency/profile', {
        method: 'PUT',
        body: { agency_id: agencyId, name: editName.trim(), photo_url: editPhoto.trim() || '' },
      });
      setAgency(res);
      setEditingProfile(false);
      toast('تم حفظ التعديلات بنجاح');
    } catch (e) {
      toast('فشل الحفظ: ' + e.message, 'error');
    } finally {
      setSavingProfile(false);
    }
  };

  if (loading) return <div className="loading">جاري التحميل...</div>;

  const balance = wallet?.diamonds_balance || 0;
  const totalRecharged = wallet?.total_recharged || 0;
  const totalWithdrawn = wallet?.total_withdrawn || 0;
  const isHosting = agency?.agency_type === 'hosting';

  return (
    <div>
      <h2 style={{ color: 'var(--gold)', marginBottom: 20, fontSize: 20 }}>لوحة التحكم</h2>

      <div className="stats-grid">
        {!isHosting && (
          <>
            <div className="stat-card">
              <div className="value">{balance.toLocaleString()}</div>
              <div className="label">رصيد الماس الحالي</div>
            </div>
            <div className="stat-card">
              <div className="value" style={{ color: 'var(--success)' }}>{totalRecharged.toLocaleString()}</div>
              <div className="label">اجمالي الشحن</div>
            </div>
            <div className="stat-card">
              <div className="value" style={{ color: 'var(--danger)' }}>{totalWithdrawn.toLocaleString()}</div>
              <div className="label">اجمالي السحب</div>
            </div>
          </>
        )}
        <div className="stat-card">
          <div className="value" style={{ color: 'var(--info)' }}>{agencyId || '—'}</div>
          <div className="label">رقم الوكالة</div>
        </div>
      </div>

      {/* Agency Profile Card */}
      <div className="card">
        <div className="card-header">
          <h3>معلومات الوكالة</h3>
          <div style={{ display: 'flex', gap: 8 }}>
            {editingProfile ? (
              <>
                <button className="btn btn-sm btn-success" onClick={handleSaveProfile} disabled={savingProfile}>
                  {savingProfile ? 'جاري الحفظ...' : 'حفظ'}
                </button>
                <button className="btn btn-sm" onClick={() => { setEditingProfile(false); setEditName(agency?.name || ''); setEditPhoto(agency?.photo_url || ''); }}>
                  إلغاء
                </button>
              </>
            ) : (
              <button className="btn btn-sm" onClick={() => setEditingProfile(true)}>
                تعديل المعلومات
              </button>
            )}
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 20, padding: '16px 20px' }}>
          {/* Photo */}
          <div style={{ position: 'relative', cursor: editingProfile ? 'pointer' : 'default' }} onClick={() => editingProfile && fileRef.current?.click()}>
            <input
              ref={fileRef}
              type="file"
              accept="image/*"
              onChange={handlePhotoUpload}
              style={{ display: 'none' }}
            />
            <img
              src={editPhoto || agency?.photo_url || 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect fill="%23222" width="100" height="100" rx="16"/><text x="50" y="55" text-anchor="middle" fill="%23666" font-size="32">🏢</text></svg>'}
              alt="agency"
              style={{
                width: 100, height: 100, borderRadius: 16, objectFit: 'cover',
                border: '2px solid var(--border)', opacity: uploading ? 0.5 : 1,
              }}
              onError={e => { e.target.src = 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect fill="%23222" width="100" height="100" rx="16"/><text x="50" y="55" text-anchor="middle" fill="%23666" font-size="32">🏢</text></svg>'; }}
            />
            {editingProfile && (
              <div style={{
                position: 'absolute', bottom: 0, left: 0, right: 0, textAlign: 'center',
                background: 'rgba(0,0,0,0.7)', color: '#fff', fontSize: 9, padding: '2px 0',
                borderRadius: '0 0 16px 16px',
              }}>
                {uploading ? 'جاري الرفع...' : '📷 اضغط للتعديل'}
              </div>
            )}
          </div>

          {/* Info */}
          <div style={{ flex: 1 }}>
            <table style={{ width: '100%' }}>
              <tbody>
                <tr>
                  <td style={{ color: 'var(--muted)', width: 150 }}>اسم الوكالة</td>
                  <td>
                    {editingProfile ? (
                      <input
                        value={editName}
                        onChange={e => setEditName(e.target.value)}
                        style={{
                          width: '100%', maxWidth: 300, padding: '6px 10px', borderRadius: 8,
                          border: '1px solid var(--border)', background: 'var(--bg)', color: 'var(--text)', fontSize: 14,
                        }}
                      />
                    ) : (
                      <span style={{ fontSize: 18, fontWeight: 700 }}>{agency?.name || 'وكالة'}</span>
                    )}
                  </td>
                </tr>
                <tr>
                  <td style={{ color: 'var(--muted)' }}>رقم الوكالة</td>
                  <td style={{ fontSize: 16, fontWeight: 700, letterSpacing: 4, fontFamily: 'monospace' }}>{agencyId || 'غير محدد'}</td>
                </tr>
                <tr>
                  <td style={{ color: 'var(--muted)' }}>نوع الوكالة</td>
                  <td>
                    <span style={{
                      padding: '2px 10px', borderRadius: 12, fontSize: 12, fontWeight: 600,
                      background: agency?.agency_type === 'shipping' ? 'rgba(245,158,11,0.15)' : agency?.agency_type === 'hosting' ? 'rgba(6,182,212,0.15)' : 'rgba(168,85,247,0.15)',
                      color: agency?.agency_type === 'shipping' ? '#f59e0b' : agency?.agency_type === 'hosting' ? '#06b6d4' : '#a855f7',
                    }}>
                      {agency?.agency_type === 'shipping' ? 'شحن ماس' : agency?.agency_type === 'hosting' ? 'استضافة' : 'مختلط'}
                    </span>
                  </td>
                </tr>
                <tr>
                  <td style={{ color: 'var(--muted)' }}>البريد الإلكتروني</td>
                  <td>{session.user?.email || '—'}</td>
                </tr>
                {!isHosting && (
                  <tr>
                    <td style={{ color: 'var(--muted)' }}>الرصيد الحالي</td>
                    <td style={{ color: 'var(--gold)', fontWeight: 700 }}>{balance.toLocaleString()} ماس</td>
                  </tr>
                )}
                <tr>
                  <td style={{ color: 'var(--muted)' }}>آخر تحديث</td>
                  <td>{wallet?.updated_at ? new Date(wallet.updated_at).toLocaleString('ar') : '—'}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Quick Actions — hidden for hosting agencies */}
      {!isHosting && (
        <div className="card" style={{ marginTop: 16 }}>
          <div className="card-header">
            <h3>إجراءات سريعة</h3>
          </div>
          <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
            <button className="btn btn-gold" onClick={() => window.location.hash = 'recharge'}>
              شحن ماس
            </button>
            <button className="btn btn-danger" onClick={() => window.location.hash = 'recharge'}>
              سحب ماس
            </button>
            <button className="btn btn-success" onClick={() => window.location.hash = 'members'}>
              إدارة الأعضاء
            </button>
            <button className="btn btn-sm" onClick={() => window.location.hash = 'logs'} style={{ background: 'var(--border)', color: 'var(--text)' }}>
              السجلات
            </button>
          </div>
        </div>
      )}

      {isHosting && (
        <div className="card" style={{ marginTop: 16 }}>
          <div className="card-header">
            <h3>إجراءات سريعة</h3>
          </div>
          <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
            <button className="btn btn-success" onClick={() => window.location.hash = 'members'}>
              إدارة الأعضاء
            </button>
            <button className="btn btn-sm" onClick={() => window.location.hash = 'logs'} style={{ background: 'var(--border)', color: 'var(--text)' }}>
              السجلات
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
