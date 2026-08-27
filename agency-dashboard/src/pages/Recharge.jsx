import { useState } from 'react';
import { api } from '../lib/api';

export default function Recharge({ session, toast }) {
  const [tab, setTab] = useState('recharge'); // 'recharge' | 'withdraw'
  const [targetId, setTargetId] = useState('');
  const [diamonds, setDiamonds] = useState('');
  const [loading, setLoading] = useState(false);
  const [targetUser, setTargetUser] = useState(null);
  const [searching, setSearching] = useState(false);

  const agencyId = session.agency_id;

  const searchUser = async () => {
    if (!targetId.trim()) return;
    setSearching(true);
    setTargetUser(null);
    try {
      const data = await api(`/api/agency/user/${targetId.trim()}/balance`);
      setTargetUser(data);
    } catch (e) {
      toast('المستخدم غير موجود: ' + e.message, 'error');
    } finally {
      setSearching(false);
    }
  };

  const handleRecharge = async (e) => {
    e.preventDefault();
    if (!targetId || !diamonds || Number(diamonds) <= 0) {
      toast('أدخل رقم المستخدم وعدد الماس', 'error');
      return;
    }
    setLoading(true);
    try {
      const d = Number(diamonds);
      const costDiamonds = Math.ceil(d * 10); // 10 coins per diamond (editable)
      const res = await api('/api/agency/recharge', {
        method: 'POST',
        body: {
          agency_id: agencyId,
          target_user_id: targetUser?.auth_uid || targetId.trim(),
          target_numeric_id: targetUser?.numeric_id || targetId.trim(),
          diamonds: d,
          cost_diamonds: costDiamonds,
        },
      });
      if (res.ok) {
        toast(`تم شحن ${d.toLocaleString()} ماس بنجاح! الرصيد المتبقي: ${res.remaining_balance?.toLocaleString()}`);
        setTargetId('');
        setDiamonds('');
        setTargetUser(null);
      } else {
        toast(res.error || 'فشلت العملية', 'error');
      }
    } catch (e) {
      toast('خطأ: ' + e.message, 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleWithdraw = async (e) => {
    e.preventDefault();
    if (!targetId || !diamonds || Number(diamonds) <= 0) {
      toast('أدخل رقم المستخدم وعدد الماس', 'error');
      return;
    }
    setLoading(true);
    try {
      const d = Number(diamonds);
      const res = await api('/api/agency/withdraw', {
        method: 'POST',
        body: {
          agency_id: agencyId,
          source_user_id: targetUser?.auth_uid || targetId.trim(),
          source_numeric_id: targetUser?.numeric_id || targetId.trim(),
          diamonds: d,
        },
      });
      if (res.ok) {
        toast(`تم سحب ${d.toLocaleString()} ماس بنجاح! رصيد المستخدم: ${res.new_balance?.toLocaleString()}`);
        setTargetId('');
        setDiamonds('');
        setTargetUser(null);
      } else {
        toast(res.error || 'فشلت العملية', 'error');
      }
    } catch (e) {
      toast('خطأ: ' + e.message, 'error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <h2 style={{ color: 'var(--gold)', marginBottom: 20, fontSize: 20 }}>💎 شحن و سحب</h2>

      <div className="tabs">
        <button className={tab === 'recharge' ? 'active' : ''} onClick={() => setTab('recharge')}>
          📤 شحن ماس لمستخدم
        </button>
        <button className={tab === 'withdraw' ? 'active' : ''} onClick={() => setTab('withdraw')}>
          📥 سحب ماس من مستخدم
        </button>
      </div>

      <div className="card">
        <div className="card-header">
          <h3>{tab === 'recharge' ? 'شحن ماس' : 'سحب ماس'}</h3>
        </div>

        <form onSubmit={tab === 'recharge' ? handleRecharge : handleWithdraw}>
          <div className="form-row">
            <div className="form-group" style={{ flex: 2 }}>
              <label>رقم المستخدم (ID أو auth_uid)</label>
              <input
                type="text"
                value={targetId}
                onChange={(e) => setTargetId(e.target.value)}
                placeholder="أدخل رقم المستخدم"
                dir="ltr"
              />
            </div>
            <div className="form-group" style={{ flex: 0, alignSelf: 'flex-end' }}>
              <button
                type="button"
                className="btn btn-sm"
                onClick={searchUser}
                disabled={searching || !targetId}
                style={{ background: 'var(--border)', color: 'var(--text)', height: 42 }}
              >
                {searching ? '...' : '🔍 بحث'}
              </button>
            </div>
          </div>

          {targetUser && (
            <div className="card" style={{ background: 'var(--bg)', padding: 14, marginBottom: 14 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                {targetUser.photo_url && (
                  <img src={targetUser.photo_url} alt="" style={{ width: 48, height: 48, borderRadius: '50%', objectFit: 'cover' }} />
                )}
                <div>
                  <div style={{ fontWeight: 700 }}>{targetUser.name || 'غير معروف'}</div>
                  <div style={{ color: 'var(--muted)', fontSize: 12 }}>ID: {targetUser.numeric_id || targetUser.auth_uid}</div>
                </div>
                <div style={{ marginRight: 'auto', textAlign: 'left' }}>
                  <div style={{ fontSize: 13, color: 'var(--muted)' }}>الرصيد الحالي</div>
                  <div style={{ fontSize: 18, fontWeight: 800, color: 'var(--gold)' }}>
                    {(targetUser.diamonds || 0).toLocaleString()} 💎
                  </div>
                </div>
              </div>
            </div>
          )}

          <div className="form-group">
            <label>عدد الماس</label>
            <input
              type="number"
              value={diamonds}
              onChange={(e) => setDiamonds(e.target.value)}
              placeholder={tab === 'recharge' ? 'كم ماس تبي تشحن' : 'كم ماس تبي تسحب'}
              min="1"
            />
          </div>

          {tab === 'recharge' && diamonds && (
            <div style={{ padding: '10px 14px', background: 'rgba(212,167,69,0.1)', borderRadius: 8, marginBottom: 14, fontSize: 13, color: 'var(--gold)' }}>
              💰 التكلفة: {Math.ceil(Number(diamonds) * 10).toLocaleString()} ماس من رصيد الوكالة
            </div>
          )}

          <button type="submit" className={`btn ${tab === 'recharge' ? 'btn-gold' : 'btn-danger'}`} disabled={loading} style={{ width: '100%' }}>
            {loading ? 'جاري التنفيذ...' : tab === 'recharge' ? '📤 تنفيذ الشحن' : '📥 تنفيذ السحب'}
          </button>
        </form>
      </div>
    </div>
  );
}
