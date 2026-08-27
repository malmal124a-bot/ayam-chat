import { useState, useEffect } from 'react';
import { api } from '../lib/api';

export default function Members({ session, toast }) {
  const [tab, setTab] = useState('list'); // 'list' | 'salary' | 'invite'
  const [members, setMembers] = useState([]);
  const [salaryRuns, setSalaryRuns] = useState([]);
  const [loading, setLoading] = useState(true);
  const [calculating, setCalculating] = useState(false);

  // Invite form
  const [inviteNumericId, setInviteNumericId] = useState('');
  const [inviting, setInviting] = useState(false);

  const agencyId = session.agency_id;

  useEffect(() => {
    loadAll();
  }, []);

  const loadAll = async () => {
    setLoading(true);
    try {
      const [m, s] = await Promise.all([
        api(`/api/agency/members?agency_id=${agencyId}`).catch(() => []),
        api(`/api/agency/salary/runs?agency_id=${agencyId}`).catch(() => []),
      ]);
      setMembers(Array.isArray(m) ? m : []);
      setSalaryRuns(Array.isArray(s) ? s : []);
    } catch (e) {
      toast('خطأ: ' + e.message, 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleInvite = async () => {
    if (!inviteNumericId.trim()) {
      toast('أدخل الرقم التعريفي للمستخدم', 'error');
      return;
    }
    setInviting(true);
    try {
      const res = await api('/api/agency/invite-member', {
        method: 'POST',
        body: { agency_id: agencyId, target_numeric_id: inviteNumericId.trim() },
      });
      if (res.ok) {
        toast('تم إرسال الدعوة بنجاح! سيتلقى المستخدم إشعاراً.');
        setInviteNumericId('');
        setTab('list');
      } else {
        toast(res.error || 'فشل إرسال الدعوة', 'error');
      }
    } catch (e) {
      toast('خطأ: ' + e.message, 'error');
    } finally {
      setInviting(false);
    }
  };

  const handleRemoveMember = async (userId, userName) => {
    if (!confirm(`هل أنت متأكد من إزالة "${userName || userId}" من الوكالة؟\nسيتلقى المستخدم إشعاراً بالإزالة.`)) return;
    try {
      const res = await api('/api/agency/remove-member', {
        method: 'DELETE',
        body: { agency_id: agencyId, user_id: userId },
      });
      if (res.ok) {
        toast('تم إزالة العضو بنجاح');
        loadAll();
      } else {
        toast(res.error || 'فشل الإزالة', 'error');
      }
    } catch (e) {
      toast('خطأ: ' + e.message, 'error');
    }
  };

  const calculateSalary = async () => {
    if (members.length === 0) {
      toast('لا يوجد أعضاء لحساب الرواتب', 'error');
      return;
    }
    setCalculating(true);
    try {
      const userIds = members
        .map(m => m.user_id || m.uid)
        .filter(Boolean);

      if (userIds.length === 0) {
        toast('لا يوجد معرفات أعضاء صالحة', 'error');
        return;
      }

      const now = new Date();
      const periodStart = new Date(now.getTime() - 30 * 86400000).toISOString();

      const res = await api('/api/agency/salary/calculate', {
        method: 'POST',
        body: {
          agency_id: agencyId,
          user_ids: userIds,
          period_start: periodStart,
          period_end: now.toISOString(),
        },
      });

      if (res.ok) {
        toast(`تم حساب الرواتب: ${res.member_count} عضو، ${res.total_paid?.toLocaleString()} ماس`);
        loadAll();
      } else {
        toast(res.error || 'فشل حساب الرواتب', 'error');
      }
    } catch (e) {
      toast('خطأ: ' + e.message, 'error');
    } finally {
      setCalculating(false);
    }
  };

  if (loading) return <div className="loading">جاري التحميل...</div>;

  return (
    <div>
      <h2 style={{ color: 'var(--gold)', marginBottom: 20, fontSize: 20 }}>الأعضاء والرواتب</h2>

      <div className="tabs">
        <button className={tab === 'list' ? 'active' : ''} onClick={() => setTab('list')}>
          قائمة الأعضاء ({members.length})
        </button>
        <button className={tab === 'invite' ? 'active' : ''} onClick={() => setTab('invite')}>
          دعوة عضو
        </button>
        <button className={tab === 'salary' ? 'active' : ''} onClick={() => setTab('salary')}>
          جداول الرواتب ({salaryRuns.length})
        </button>
      </div>

      {tab === 'list' && (
        <div className="card">
          <div className="card-header">
            <h3>أعضاء الوكالة</h3>
            <div style={{ display: 'flex', gap: 8 }}>
              <button className="btn btn-sm btn-success" onClick={loadAll}>تحديث</button>
              <button className="btn btn-sm btn-gold" onClick={() => setTab('invite')}>+ دعوة عضو</button>
            </div>
          </div>

          {members.length === 0 ? (
            <div className="empty">لا يوجد أعضاء في الوكالة بعد. قم بدعوة أعضاء!</div>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>العضو</th>
                    <th>المعرف</th>
                    <th>الدور</th>
                    <th>الحالة</th>
                    <th>تاريخ الانضمام</th>
                    <th>إجراء</th>
                  </tr>
                </thead>
                <tbody>
                  {members.map((m, i) => (
                    <tr key={i}>
                      <td style={{ fontWeight: 600 }}>{m.name || m.username || m.user_id}</td>
                      <td style={{ color: 'var(--muted)', direction: 'ltr', textAlign: 'right' }}>{m.user_id || m.uid}</td>
                      <td>
                        <span className={`badge ${m.role === 'owner' ? 'badge-success' : m.role === 'supervisor' ? 'badge-info' : 'badge-warning'}`}>
                          {m.role === 'owner' ? 'مالك' : m.role === 'supervisor' ? 'مشرف' : 'عضو'}
                        </span>
                      </td>
                      <td>
                        <span className={`badge ${m.status === 'active' ? 'badge-success' : 'badge-warning'}`}>
                          {m.status === 'active' ? 'نشط' : m.status}
                        </span>
                      </td>
                      <td style={{ color: 'var(--muted)' }}>{m.joined_at ? new Date(m.joined_at).toLocaleDateString('ar') : '—'}</td>
                      <td>
                        {m.role !== 'owner' && (
                          <button
                            className="btn btn-sm"
                            style={{ background: 'rgba(239,68,68,0.15)', color: '#ef4444', fontSize: 11 }}
                            onClick={() => handleRemoveMember(m.user_id || m.uid, m.name || m.username)}
                          >
                            إزالة
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {tab === 'invite' && (
        <div className="card">
          <div className="card-header">
            <h3>دعوة عضو جديد</h3>
          </div>
          <p style={{ color: 'var(--muted)', fontSize: 13, marginBottom: 16 }}>
            أدخل الرقم التعريفي للمستخدم المراد دعوته. سيتلقى المستخدم إشعاراً في التطبيق ويمكنه قبول أو رفض الدعوة.
          </p>
          <div style={{ display: 'flex', gap: 12, alignItems: 'flex-end', maxWidth: 500 }}>
            <div style={{ flex: 1 }}>
              <label style={{ display: 'block', fontSize: 12, color: 'var(--muted)', marginBottom: 6 }}>الرقم التعريفي</label>
              <input
                value={inviteNumericId}
                onChange={e => setInviteNumericId(e.target.value)}
                placeholder="مثل: 123456"
                style={{
                  width: '100%', padding: '10px 14px', borderRadius: 10,
                  border: '1px solid var(--border)', background: 'var(--bg)', color: 'var(--text)',
                  fontSize: 16, letterSpacing: 2, textAlign: 'center',
                }}
                onKeyDown={e => e.key === 'Enter' && handleInvite()}
              />
            </div>
            <button
              className="btn btn-gold"
              onClick={handleInvite}
              disabled={inviting || !inviteNumericId.trim()}
              style={{ padding: '10px 24px', fontSize: 14, fontWeight: 700 }}
            >
              {inviting ? 'جاري الإرسال...' : 'إرسال الدعوة'}
            </button>
          </div>
        </div>
      )}

      {tab === 'salary' && (
        <>
          <div className="card">
            <div className="card-header">
              <h3>حساب الرواتب</h3>
              <button className="btn btn-gold" onClick={calculateSalary} disabled={calculating}>
                {calculating ? 'جاري الحساب...' : 'حساب رواتب آخر 30 يوم'}
              </button>
            </div>
            <p style={{ color: 'var(--muted)', fontSize: 13 }}>
              يحسب مجموع الماس المكتسب من الشحنات لكل عضو في آخر 30 يوم ويجدوله كراتب.
            </p>
          </div>

          <div className="card">
            <div className="card-header">
              <h3>جداول الرواتب السابقة</h3>
            </div>

            {salaryRuns.length === 0 ? (
              <div className="empty">لا توجد جداول رواتب بعد</div>
            ) : (
              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>الفترة</th>
                      <th>عدد الأعضاء</th>
                      <th>المبلغ الكلي</th>
                      <th>الحالة</th>
                      <th>إجراء</th>
                    </tr>
                  </thead>
                  <tbody>
                    {salaryRuns.map((run) => (
                      <tr key={run.id}>
                        <td style={{ fontSize: 12 }}>
                          {new Date(run.period_start).toLocaleDateString('ar')} — {new Date(run.period_end).toLocaleDateString('ar')}
                        </td>
                        <td>{run.member_count}</td>
                        <td style={{ color: 'var(--gold)', fontWeight: 700 }}>{(run.total_paid || 0).toLocaleString()} ماس</td>
                        <td>
                          <span className={`badge ${run.status === 'paid' ? 'badge-success' : run.status === 'pending' ? 'badge-warning' : 'badge-danger'}`}>
                            {run.status === 'paid' ? 'مدفوع' : run.status === 'pending' ? 'معلق' : 'ملغي'}
                          </span>
                        </td>
                        <td>
                          {run.status === 'pending' && (
                            <button
                              className="btn btn-sm btn-success"
                              onClick={async () => {
                                try {
                                  const res = await api('/api/agency/salary/pay-all', {
                                    method: 'POST',
                                    body: { run_id: run.id, agency_id: agencyId },
                                  });
                                  toast(`تم الدفع: ${res.paid} مدفوع، ${res.failed} فشل`);
                                  loadAll();
                                } catch (e) {
                                  toast('خطأ: ' + e.message, 'error');
                                }
                              }}
                            >
                              دفع الكل
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
