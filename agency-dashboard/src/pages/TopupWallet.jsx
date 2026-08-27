import { useState, useEffect } from 'react';
import { apiGet, apiPost } from '../lib/api';

export default function TopupWallet({ session, toast }) {
  const [gateways, setGateways] = useState([]);
  const [agency, setAgency] = useState(null);
  const [selectedGateway, setSelectedGateway] = useState('');
  const [amountUsd, setAmountUsd] = useState('');
  const [senderNumber, setSenderNumber] = useState('');
  const [txnRef, setTxnRef] = useState('');
  const [loading, setLoading] = useState(false);
  const [requests, setRequests] = useState([]);

  const diamondsPerUsd = 10000;
  const diamonds = Math.floor((parseFloat(amountUsd) || 0) * diamondsPerUsd);

  useEffect(() => {
    loadGateways();
    loadAgency();
    loadRequests();
  }, []);

  const agencyId = session?.agency_id;

  const loadGateways = async () => {
    try {
      const data = await apiGet('/api/agency/payment-gateways');
      setGateways(data || []);
    } catch (e) {
      console.error(e);
    }
  };

  const loadAgency = async () => {
    if (!agencyId) return;
    try {
      const data = await apiGet(`/api/agency/profile?agency_id=${agencyId}`);
      setAgency(data);
    } catch (e) {
      console.error(e);
    }
  };

  const loadRequests = async () => {
    if (!agencyId) return;
    try {
      const data = await apiGet(`/api/agency/topup-requests?agency_id=${agencyId}`);
      setRequests(data || []);
    } catch (e) {
      console.error(e);
    }
  };

  const handleSubmit = async () => {
    if (!agencyId || !selectedGateway || !amountUsd || parseFloat(amountUsd) <= 0) {
      toast('يرجى ملء جميع الحقول', 'error');
      return;
    }
    setLoading(true);
    try {
      const result = await apiPost('/api/agency/topup-request', {
        agency_id: agencyId,
        gateway_id: selectedGateway,
        amount_usd: parseFloat(amountUsd),
        diamonds: diamonds,
        sender_number: senderNumber,
        transaction_ref: txnRef,
      });
      if (result?.id) {
        toast('تم إرسال طلب الشحن بنجاح! في انتظار مراجعة الإدارة');
        setAmountUsd('');
        setSenderNumber('');
        setTxnRef('');
        setSelectedGateway('');
        loadRequests();
      } else {
        toast(result?.error || 'فشل إرسال الطلب', 'error');
      }
    } catch (e) {
      toast('حدث خطأ: ' + e.message, 'error');
    }
    setLoading(false);
  };

  const gw = gateways.find(g => g.id === selectedGateway);
  const statusColors = { pending: '#f59e0b', approved: '#10b981', rejected: '#ef4444' };
  const statusLabels = { pending: 'قيد المراجعة', approved: 'تمت الموافقة', rejected: 'مرفوض' };

  return (
    <div style={{ padding: 24, maxWidth: 700 }}>
      <h2 style={{ color: '#fff', fontSize: 18, marginBottom: 8 }}>شحن رصيد الوكالة</h2>
      <p style={{ color: '#94a3b8', fontSize: 12, marginBottom: 24 }}>
        اختر بوابة الدفع وأرسل المبلغ، ثم أكمل البيانات للمراجعة
      </p>

      {/* Gateway selection */}
      <div style={{ marginBottom: 16 }}>
        <label style={{ color: '#94a3b8', fontSize: 11, display: 'block', marginBottom: 6 }}>بوابة الدفع</label>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: 8 }}>
          {gateways.map(g => (
            <button key={g.id} onClick={() => setSelectedGateway(g.id)}
              style={{
                padding: '12px 16px', borderRadius: 12, border: selectedGateway === g.id ? '2px solid #6366f1' : '1px solid rgba(255,255,255,0.1)',
                background: selectedGateway === g.id ? 'rgba(99,102,241,0.15)' : '#1a1a1f',
                color: '#fff', cursor: 'pointer', textAlign: 'center',
              }}>
              <div style={{ fontSize: 13, fontWeight: 600 }}>{g.name_ar}</div>
              <div style={{ fontSize: 10, color: '#64748b', marginTop: 4 }}>{g.account_number || g.wallet_address || ''}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Gateway instructions */}
      {gw && (gw.instructions_ar || gw.account_number) && (
        <div style={{ background: 'rgba(99,102,241,0.1)', borderRadius: 12, padding: 16, marginBottom: 16, border: '1px solid rgba(99,102,241,0.2)' }}>
          <p style={{ color: '#a5b4fc', fontSize: 12, fontWeight: 600, marginBottom: 8 }}>تعليمات الدفع</p>
          {gw.account_number && <p style={{ color: '#e2e8f0', fontSize: 12 }}>رقم الحساب: <strong style={{ color: '#fff' }}>{gw.account_number}</strong></p>}
          {gw.account_name && <p style={{ color: '#e2e8f0', fontSize: 12 }}>الاسم: {gw.account_name}</p>}
          {gw.bank_name && <p style={{ color: '#e2e8f0', fontSize: 12 }}>البنك: {gw.bank_name}</p>}
          {gw.instructions_ar && <p style={{ color: '#94a3b8', fontSize: 11, marginTop: 8, whiteSpace: 'pre-wrap' }}>{gw.instructions_ar}</p>}
        </div>
      )}

      {/* Amount */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 16 }}>
        <div>
          <label style={{ color: '#94a3b8', fontSize: 11, display: 'block', marginBottom: 4 }}>المبلغ بالدولار</label>
          <input type="number" value={amountUsd} onChange={e => setAmountUsd(e.target.value)}
            placeholder="0.00" min="1"
            style={{ width: '100%', padding: '10px 12px', background: '#1a1a1f', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: '#fff', fontSize: 13, boxSizing: 'border-box' }} />
          {diamonds > 0 && <p style={{ color: '#10b981', fontSize: 11, marginTop: 4 }}>💎 {diamonds.toLocaleString()} ماس</p>}
        </div>
        <div>
          <label style={{ color: '#94a3b8', fontSize: 11, display: 'block', marginBottom: 4 }}>رقم المرسل (اختياري)</label>
          <input value={senderNumber} onChange={e => setSenderNumber(e.target.value)}
            placeholder="09xxxxxxxx"
            style={{ width: '100%', padding: '10px 12px', background: '#1a1a1f', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: '#fff', fontSize: 13, boxSizing: 'border-box' }} />
        </div>
      </div>

      <div style={{ marginBottom: 16 }}>
        <label style={{ color: '#94a3b8', fontSize: 11, display: 'block', marginBottom: 4 }}>رقم المعاملة (اختياري)</label>
        <input value={txnRef} onChange={e => setTxnRef(e.target.value)}
          placeholder="رقم الإيصال أو المعاملة"
          style={{ width: '100%', padding: '10px 12px', background: '#1a1a1f', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: '#fff', fontSize: 13, boxSizing: 'border-box' }} />
      </div>

      <button onClick={handleSubmit} disabled={loading || !selectedGateway || !amountUsd}
        style={{
          width: '100%', padding: '12px 0', background: loading || !selectedGateway || !amountUsd ? '#334155' : '#6366f1',
          color: '#fff', border: 'none', borderRadius: 10, fontSize: 13, fontWeight: 600, cursor: loading ? 'wait' : 'pointer',
        }}>
        {loading ? 'جاري الإرسال...' : 'إرسال طلب الشحن'}
      </button>

      {/* History */}
      <div style={{ marginTop: 32 }}>
        <h3 style={{ color: '#fff', fontSize: 14, marginBottom: 12 }}>طلبات الشحن السابقة</h3>
        {requests.length === 0 && <p style={{ color: '#475569', fontSize: 12 }}>لا توجد طلبات</p>}
        {requests.map(r => (
          <div key={r.id} style={{ background: '#1a1a1f', borderRadius: 10, padding: 12, marginBottom: 8, border: '1px solid rgba(255,255,255,0.05)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <span style={{ color: '#fff', fontSize: 12, fontWeight: 600 }}>${r.amount_usd}</span>
                <span style={{ color: '#64748b', fontSize: 11, marginRight: 8 }}>→ {r.diamonds?.toLocaleString()} 💎</span>
              </div>
              <span style={{ color: statusColors[r.status], fontSize: 11, fontWeight: 600 }}>{statusLabels[r.status]}</span>
            </div>
            <p style={{ color: '#475569', fontSize: 10, marginTop: 4 }}>{new Date(r.created_at).toLocaleString('ar')}</p>
            {r.admin_note && <p style={{ color: '#ef4444', fontSize: 10, marginTop: 2 }}>ملاحظة: {r.admin_note}</p>}
          </div>
        ))}
      </div>
    </div>
  );
}
