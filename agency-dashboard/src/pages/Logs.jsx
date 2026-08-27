import { useState, useEffect } from 'react';
import { api } from '../lib/api';

export default function Logs({ session, toast }) {
  const [tab, setTab] = useState('recharges');
  const [recharges, setRecharges] = useState([]);
  const [withdrawals, setWithdrawals] = useState([]);
  const [loading, setLoading] = useState(true);

  const agencyId = session.agency_id;

  useEffect(() => {
    loadLogs();
  }, []);

  const loadLogs = async () => {
    setLoading(true);
    try {
      const [r, w] = await Promise.all([
        api(`/api/agency/logs/recharges?agency_id=${agencyId}&limit=100`).catch(() => []),
        api(`/api/agency/logs/withdrawals?agency_id=${agencyId}&limit=100`).catch(() => []),
      ]);
      setRecharges(Array.isArray(r) ? r : []);
      setWithdrawals(Array.isArray(w) ? w : []);
    } catch (e) {
      toast('خطأ: ' + e.message, 'error');
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div className="loading">جاري التحميل...</div>;

  return (
    <div>
      <h2 style={{ color: 'var(--gold)', marginBottom: 20, fontSize: 20 }}>📋 السجلات</h2>

      <div className="tabs">
        <button className={tab === 'recharges' ? 'active' : ''} onClick={() => setTab('recharges')}>
          📤 سجل الشحنات ({recharges.length})
        </button>
        <button className={tab === 'withdrawals' ? 'active' : ''} onClick={() => setTab('withdrawals')}>
          📥 سجل السحوبات ({withdrawals.length})
        </button>
      </div>

      {tab === 'recharges' && (
        <div className="card">
          <div className="card-header">
            <h3>شحنات ماس</h3>
            <button className="btn btn-sm btn-success" onClick={loadLogs}>🔄 تحديث</button>
          </div>

          {recharges.length === 0 ? (
            <div className="empty">لا توجد شحنات بعد</div>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>التاريخ</th>
                    <th>المستخدم</th>
                    <th>الماس المحمل</th>
                    <th>التكلفة</th>
                    <th>الحالة</th>
                  </tr>
                </thead>
                <tbody>
                  {recharges.map((r) => (
                    <tr key={r.id}>
                      <td style={{ fontSize: 12, color: 'var(--muted)' }}>
                        {new Date(r.created_at).toLocaleString('ar')}
                      </td>
                      <td>
                        <div style={{ fontWeight: 600 }}>{r.target_user_id}</div>
                        {r.target_numeric_id && (
                          <div style={{ fontSize: 11, color: 'var(--muted)' }}>{r.target_numeric_id}</div>
                        )}
                      </td>
                      <td style={{ color: 'var(--success)', fontWeight: 700 }}>
                        +{r.diamonds?.toLocaleString()} 💎
                      </td>
                      <td style={{ color: 'var(--danger)' }}>
                        -{r.cost_diamonds?.toLocaleString()} 💎
                      </td>
                      <td>
                        <span className={`badge ${r.status === 'completed' ? 'badge-success' : r.status === 'reversed' ? 'badge-danger' : 'badge-warning'}`}>
                          {r.status === 'completed' ? 'ناجح' : r.status === 'reversed' ? 'معكوس' : r.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {tab === 'withdrawals' && (
        <div className="card">
          <div className="card-header">
            <h3>سحوبات ماس</h3>
            <button className="btn btn-sm btn-success" onClick={loadLogs}>🔄 تحديث</button>
          </div>

          {withdrawals.length === 0 ? (
            <div className="empty">لا توجد سحوبات بعد</div>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>التاريخ</th>
                    <th>المستخدم</th>
                    <th>الماس المسحوب</th>
                    <th>الحالة</th>
                  </tr>
                </thead>
                <tbody>
                  {withdrawals.map((w) => (
                    <tr key={w.id}>
                      <td style={{ fontSize: 12, color: 'var(--muted)' }}>
                        {new Date(w.created_at).toLocaleString('ar')}
                      </td>
                      <td>
                        <div style={{ fontWeight: 600 }}>{w.source_user_id}</div>
                        {w.source_numeric_id && (
                          <div style={{ fontSize: 11, color: 'var(--muted)' }}>{w.source_numeric_id}</div>
                        )}
                      </td>
                      <td style={{ color: 'var(--danger)', fontWeight: 700 }}>
                        -{w.diamonds?.toLocaleString()} 💎
                      </td>
                      <td>
                        <span className={`badge ${w.status === 'completed' ? 'badge-success' : 'badge-warning'}`}>
                          {w.status === 'completed' ? 'ناجح' : w.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
