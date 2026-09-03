import { useContext, useEffect, useState } from 'react';
import {
  HostAgencyModel, HostAgencyMemberModel, CommissionSettingModel,
  HostMilestoneModel, AgencyJoinRequestModel, AgencyLedgerEntryModel,
  AgencyWithdrawalRequestModel, AgencyOpenRequestModel,
} from '../types';
import {
  getHostAgencies, createHostAgency, updateHostAgency, deleteHostAgency, openAgencyForUser,
  getCommissionSettings, updateCommissionSetting,
  getHostAgencyMembers, getHostMilestones, updateHostMilestone,
  createHostMilestone, deleteHostMilestone,
  getHostAgencyJoinRequests, approveJoinRequest, rejectJoinRequest,
  updateAgencyMemberRole, removeAgencyMember,
  getAgencyLedger, getWithdrawalRequests, approveWithdrawal, rejectWithdrawal,
  getAgencyOpenRequests, approveAgencyOpenRequest, rejectAgencyOpenRequest,
} from '../lib/db';
import { supabase, getAdminSupabase } from '../lib/supabase';

const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'https://backend-seven-brown-72.vercel.app';
const AGENCY_DASH_URL = import.meta.env.VITE_AGENCY_DASHBOARD_URL || 'https://agency-dashboard-sage-kappa.vercel.app';
async function adminApi(path: string, body: Record<string, unknown> = {}) {
  let serviceRoleKey = '';
  try {
    const raw = localStorage.getItem('supabase_admin_config');
    if (raw) { const cfg = JSON.parse(raw); serviceRoleKey = (cfg.serviceRoleKey || '').trim(); }
  } catch {}
  // Use service role key if available, otherwise fallback to admin password
  const token = serviceRoleKey || import.meta.env.VITE_ADMIN_PASS || 'ayam-admin';
  const resp = await fetch(`${BACKEND_URL}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  const data = await resp.json();
  if (data.ok === false) throw new Error(data.error || 'API error');
  return data;
}
import { I18nContext } from '../lib/i18n';
import DataTable from '../components/DataTable';
import { Handshake, Users, UserPlus, Wallet, Target, Settings, CreditCard, ArrowDownToLine, FilePlus } from 'lucide-react';

const tabs = [
  { key: 'agencies', labelKey: 'agency.agencies', icon: Handshake },
    { key: 'open_requests', label: 'طلبات فتح وكالة', icon: FilePlus },{ key: 'members', labelKey: 'agency.members', icon: Users },
  { key: 'join_requests', labelKey: 'agency.joinRequests', icon: UserPlus },
  { key: 'financial', labelKey: 'agency.financial', icon: Wallet },
  { key: 'milestones', labelKey: 'agency.milestones', icon: Target },
  { key: 'commission', labelKey: 'agency.commission', icon: Settings },
  { key: 'gift_commission', labelKey: 'عمولة الهدايا', icon: Settings },
  { key: 'profit_levels', labelKey: 'مستويات الأرباح', icon: Target },
  { key: 'payment_gateways', labelKey: 'بوابتات الدفع', icon: CreditCard },
  { key: 'topup_requests', labelKey: 'طلبات الشحن', icon: ArrowDownToLine },
] as const;
type Tab = typeof tabs[number]['key'];

export default function AgencyPage() {
  const [tab, setTab] = useState<Tab>('agencies');
  const { t } = useContext(I18nContext);

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <Handshake className="w-5 h-5 text-indigo-400" />
        <h2 className="text-white text-lg font-semibold">{t('agency.title')}</h2>
      </div>
      <div className="flex gap-2 flex-wrap">
        {tabs.map(tabItem => (
          <button key={tabItem.key} onClick={() => setTab(tabItem.key)}
            className={`flex items-center gap-1.5 px-4 py-2 text-xs rounded-lg font-semibold transition-colors ${tab === tabItem.key ? 'bg-indigo-500/20 text-indigo-300' : 'text-slate-400 hover:text-white'}`}>
            <tabItem.icon className="w-3.5 h-3.5" />
            {t(tabItem.labelKey)}
          </button>
        ))}
      </div>
      {tab === 'agencies' && <AgenciesTab />}
      {tab === 'open_requests' && <OpenRequestsTab />}
      {tab === 'members' && <MembersTab />}
      {tab === 'join_requests' && <JoinRequestsTab />}
      {tab === 'financial' && <FinancialTab />}
      {tab === 'milestones' && <MilestonesTab />}
      {tab === 'commission' && <CommissionTab />}
      {tab === 'gift_commission' && <GiftCommissionTab />}
      {tab === 'profit_levels' && <ProfitLevelsTab />}
      {tab === 'payment_gateways' && <PaymentGatewaysTab />}
      {tab === 'topup_requests' && <TopupRequestsTab />}
    </div>
  );
}

/* =============================================================
   1. AGENCIES TAB
   ============================================================= */
function AgenciesTab() {
  const { t } = useContext(I18nContext);
  const [agencies, setAgencies] = useState<HostAgencyModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [ownerId, setOwnerId] = useState('');
  const [commissionRate, setCommissionRate] = useState('5');
  const [specialty, setSpecialty] = useState('mixed');
  const [description, setDescription] = useState('');
  const [country, setCountry] = useState('');
  const [tier, setTier] = useState('bronze');
  const [photoUrl, setPhotoUrl] = useState('');
  const [agencyType, setAgencyType] = useState('mixed');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [viewMembersAgency, setViewMembersAgency] = useState<string | null>(null);
  const [createResult, setCreateResult] = useState<{ ok: boolean; agency_id?: string; email?: string; password?: string; error?: string } | null>(null);
  const [creating, setCreating] = useState(false);

  const load = () => { setLoading(true); getHostAgencies().then(d => { setAgencies(d); setLoading(false); }); };
  useEffect(() => { load(); }, []);

  const filteredAgencies = typeFilter === 'all' ? agencies : agencies.filter(a => (a as any).agency_type === typeFilter);

  const resetForm = () => {
    setName(''); setOwnerId(''); setCommissionRate('5'); setSpecialty('mixed');
    setDescription(''); setCountry(''); setTier('bronze'); setEditId(null);
    setPhotoUrl(''); setAgencyType('mixed');
  };

  const openEdit = (a: HostAgencyModel) => {
    setName(a.name ?? ''); setOwnerId(a.owner_id ?? ''); setCommissionRate(String((a.commission_rate ?? 0) * 100));
    setSpecialty(a.specialty); setDescription(a.description ?? ''); setCountry(a.country ?? '');
    setTier(a.tier ?? 'bronze'); setEditId(a.id); setShowForm(true);
    setPhotoUrl((a as any).photo_url ?? (a as any).owner_photo ?? '');
    setAgencyType((a as any).agency_type || a.specialty || 'mixed');
  };

  const handleSubmit = async () => {
    if (!name?.trim()) return;
    if (editId) {
      // Edit: update existing agency
      await supabase.from('agencies').update({
        name: name.trim(),
        description: description.trim() || null,
        commission_rate: (parseInt(commissionRate) || 0) / 100,
        agency_type: agencyType,
        photo_url: photoUrl.trim() || '',
      }).eq('id', editId);
      resetForm(); setShowForm(false); setCreateResult(null); load();
    } else {
      // Create: call backend → creates agency + auth account + wallet
      if (!ownerId?.trim()) return;
      setCreating(true);
      setCreateResult(null);
      try {
        const res = await adminApi('/api/admin/open-agency', {
          numeric_id: ownerId.trim(),
          agency_type: agencyType,
          agency_name: name.trim(),
        });
        if (res.ok) {
          setCreateResult({ ok: true, agency_id: res.agency_id, email: res.dashboard_email, password: res.dashboard_password });
          load();
        } else {
          setCreateResult({ ok: false, error: res.error });
        }
      } catch (e: any) {
        setCreateResult({ ok: false, error: e.message });
      }
      setCreating(false);
    }
  };

  const tierColors: Record<string, string> = {
    bronze: 'text-amber-600', silver: 'text-slate-300', gold: 'text-yellow-400',
    platinum: 'text-cyan-300', diamond: 'text-blue-400',
  };

  const tierKey = (v: string) => `agency.tier.${v}` as const;

  return (
    <div>
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-3">
          <p className="text-slate-500 text-xs">{filteredAgencies.length} {t('agency.agenciesCount')}</p>
          <div className="flex gap-1">
            {[
              { key: 'all', label: 'الكل' },
              { key: 'shipping', label: 'شحن ماس' },
              { key: 'hosting', label: 'استضافة' },
              { key: 'mixed', label: 'مختلط' },
            ].map(opt => (
              <button key={opt.key} onClick={() => setTypeFilter(opt.key)}
                className={`text-[10px] px-2 py-0.5 rounded-full font-semibold transition-colors ${typeFilter === opt.key ? 'bg-indigo-500/20 text-indigo-300' : 'text-slate-500 hover:text-white'}`}>
                {opt.label}
              </button>
            ))}
          </div>
        </div>
        <button onClick={() => { resetForm(); setShowForm(!showForm); }}
          className="text-xs bg-indigo-500 hover:bg-indigo-600 text-white px-3 py-1.5 rounded-lg font-semibold transition-colors">
          {showForm ? t('cancel') : t('agency.newAgency')}
        </button>
      </div>
      {showForm && (
        <div className="bg-[#141417] rounded-2xl border border-white/5 p-4 mb-4 space-y-3">
          <div className="grid grid-cols-3 gap-3">
            <input value={name} onChange={e => setName(e.target.value)} placeholder={t('agency.name')}
              className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
            <input value={ownerId} onChange={e => setOwnerId(e.target.value)} placeholder={editId ? 'النوع فقط قابل للتعديل' : 'الرقم التعريفي للمستخدم (مثل: 271555)'}
              readOnly={!!editId}
              className={`w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs ${editId ? 'text-slate-500' : 'text-white'} focus:outline-none focus:border-indigo-500 placeholder:text-slate-600`} />
            <input value={photoUrl} onChange={e => setPhotoUrl(e.target.value)} placeholder="رابط الصورة"
              className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
          </div>
          <div className="grid grid-cols-4 gap-3">
            <input type="number" value={commissionRate} onChange={e => setCommissionRate(e.target.value)} placeholder={t('agency.commission')}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
            <select value={agencyType} onChange={e => { setAgencyType(e.target.value); setSpecialty(e.target.value); }}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
              <option value="shipping">شحن ماس</option>
              <option value="hosting">استضافة</option>
              <option value="mixed">مختلط</option>
            </select>
            <select value={tier} onChange={e => setTier(e.target.value)}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
              {['bronze', 'silver', 'gold', 'platinum', 'diamond'].map(v => (
                <option key={v} value={v}>{t(tierKey(v))}</option>
              ))}
            </select>
            <input value={country} onChange={e => setCountry(e.target.value)} placeholder={t('agency.country')}
              className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
          </div>
          <textarea value={description} onChange={e => setDescription(e.target.value)} placeholder={t('agency.description')}
            className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600 resize-none h-16" />
          {!editId && createResult && (
            <div className={`p-3 rounded-lg text-xs ${createResult.ok ? 'bg-emerald-500/10 border border-emerald-500/30 text-emerald-400' : 'bg-rose-500/10 border border-rose-500/30 text-rose-400'}`}>
              {createResult.ok ? (
                <div className="space-y-1">
                  <p className="font-bold text-sm mb-2">تم فتح الوكالة بنجاح!</p>
                  <p>اسم الوكالة: <span className="text-white font-mono">{name}</span></p>
                  <p>رقم الوكالة: <span className="text-white font-mono">{createResult.agency_id}</span></p>
                  <p>البريد: <span className="text-white font-mono">{createResult.email}</span></p>
                  <p>كلمة المرور: <span className="text-white font-mono">{createResult.password}</span></p>
                  <button
                    onClick={() => {
                      window.open(`${AGENCY_DASH_URL}#agency_id=${createResult.agency_id}&email=${createResult.email}&password=${createResult.password}`, '_blank');
                    }}
                    className="mt-2 text-xs bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-1.5 rounded-lg font-semibold"
                  >
                    فتح لوحة تحكم الوكالة
                  </button>
                </div>
              ) : (
                <p>خطأ: {createResult.error}</p>
              )}
            </div>
          )}
          <div className="flex gap-2">
            <button onClick={handleSubmit} disabled={creating}
              className="text-xs bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-white px-4 py-1.5 rounded-lg font-semibold transition-colors">
              {creating ? 'جاري الفتح...' : editId ? t('agency.updateAgency') : t('agency.createAgency')}
            </button>
            {editId && (
              <button onClick={() => { resetForm(); setShowForm(false); setCreateResult(null); }}
                className="text-xs bg-slate-600 hover:bg-slate-700 text-white px-3 py-1.5 rounded-lg font-semibold transition-colors">
                {t('agency.cancelEdit')}
              </button>
            )}
          </div>
        </div>
      )}
      <DataTable
        loading={loading}
        columns={[
          { key: 'name', label: t('agency.col.name'), sortable: true },
          { key: 'agency_type', label: 'النوع', sortable: true, render: a => {
            const at = (a as any).agency_type;
            const colors: Record<string, string> = { shipping: 'text-amber-400 bg-amber-400/10', hosting: 'text-cyan-400 bg-cyan-400/10', mixed: 'text-purple-400 bg-purple-400/10' };
            const labels: Record<string, string> = { shipping: 'شحن', hosting: 'استضافة', mixed: 'مختلط' };
            return <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${colors[at] || 'text-slate-400'}`}>{labels[at] || at || '—'}</span>;
          }},
          { key: 'owner_id', label: 'المالك', sortable: true, render: a => {
            const h = a as HostAgencyModel;
            return (
              <div className="flex items-center gap-2">
                {(h as any).owner_photo ? (
                  <img src={(h as any).owner_photo} alt="" className="w-6 h-6 rounded-full object-cover border border-white/20" />
                ) : (
                  <div className="w-6 h-6 rounded-full bg-indigo-500/30 flex items-center justify-center text-[10px] text-indigo-300 font-bold">
                    {(h.owner_name || h.owner_id || '?')[0]}
                  </div>
                )}
                <span className="text-cyan-400 text-[10px] font-mono">{h.owner_name || h.owner_id?.slice(0, 8) || '—'}</span>
              </div>
            );
          }},
          { key: 'tier', label: t('agency.col.tier'), sortable: true, render: a => {
            const h = a as HostAgencyModel;
            const tierT = t(tierKey(h.tier ?? 'bronze'));
            return <span className={tierColors[h.tier ?? 'bronze'] + ' font-semibold'}>{tierT}</span>;
          }},
          { key: 'specialty', label: t('agency.col.specialty'), sortable: true, render: a => {
            const s = (a as HostAgencyModel).specialty;
            return <span className="text-slate-400">{t(`agency.specialty.${s}` as any)}</span>;
          }},
          { key: 'commission_rate', label: t('agency.col.commission'), sortable: true, render: a => {
            const rate = (a as HostAgencyModel).commission_rate;
            return <span>{((rate ?? 0) * 100).toFixed(0)}%</span>;
          }},
          { key: 'member_count', label: t('agency.col.members'), sortable: true },
          { key: 'total_diamonds_earned', label: t('agency.col.totalDiamonds'), sortable: true, render: a => <span className="text-cyan-400">{(a as HostAgencyModel).total_diamonds_earned?.toLocaleString() ?? '0'}</span> },
          { key: 'monthly_diamonds', label: t('agency.col.monthlyDiamonds'), sortable: true, render: a => <span className="text-amber-400">{(a as HostAgencyModel).monthly_diamonds?.toLocaleString() ?? '0'}</span> },
          { key: 'country', label: t('agency.col.country'), sortable: true, render: a => <span className="text-slate-500 uppercase">{(a as HostAgencyModel).country || '—'}</span> },
          { key: 'is_active', label: t('agency.col.active'), sortable: true, render: a => {
            const active = (a as HostAgencyModel).is_active;
            return <span className={active ? 'text-emerald-400' : 'text-rose-400'}>{active ? t('agency.yes') : t('agency.no')}</span>;
          }},
        ]}
        data={filteredAgencies}
        searchKeys={['name', 'owner_id', 'specialty', 'country', 'tier']}
        onEdit={a => openEdit(a as HostAgencyModel)}
        onDelete={async a => {
          if (confirm(t('agency.deleteConfirm'))) { await deleteHostAgency((a as HostAgencyModel).id); load(); }
        }}
        actions={a => {
          const h = a as HostAgencyModel;
          return (
            <div className="flex items-center gap-2">
              <button
                onClick={() => setViewMembersAgency(viewMembersAgency === h.id ? null : h.id)}
                className={`text-[10px] font-semibold px-2 py-0.5 rounded ${viewMembersAgency === h.id ? 'text-cyan-400 bg-cyan-400/10' : 'text-cyan-400 hover:text-cyan-300'}`}
              >
                الأعضاء
              </button>
              <button
                onClick={async () => {
                  await updateHostAgency(h.id, { is_active: !h.is_active } as any);
                  load();
                }}
                className={`text-[10px] font-semibold px-2 py-0.5 rounded ${h.is_active ? 'text-amber-400 hover:text-amber-300' : 'text-emerald-400 hover:text-emerald-300'}`}
              >
                {h.is_active ? 'إيقاف' : 'تفعيل'}
              </button>
            </div>
          );
        }}
      />

      {viewMembersAgency && <AgencyMembersPanel agencyId={viewMembersAgency} />}

      <div className="mt-6 bg-[#141417] rounded-2xl border border-white/5 p-4 space-y-3">
        <p className="text-white text-xs font-semibold">فتح وكالة لمستخدم</p>
        <OpenAgencyForUser load={load} />
      </div>
    </div>
  );
}

function OpenAgencyForUser({ load }: { load: () => void }) {
  const [numericId, setNumericId] = useState('');
  const [agencyType, setAgencyType] = useState('shipping');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<{ ok: boolean; agency_id?: string; email?: string; password?: string; error?: string } | null>(null);

  const handleOpen = async () => {
    if (!numericId.trim()) return;
    setLoading(true);
    setResult(null);
    try {
      const res = await adminApi('/api/admin/open-agency', {
        numeric_id: numericId.trim(),
        agency_type: agencyType,
      });
      if (res.ok) {
        setResult({ ok: true, agency_id: res.agency_id, email: res.dashboard_email, password: res.dashboard_password });
        setNumericId('');
        load();
      } else {
        setResult({ ok: false, error: res.error });
      }
    } catch (e: any) {
      setResult({ ok: false, error: e.message });
    }
    setLoading(false);
  };

  return (
    <div>
      <div className="flex gap-2 items-end">
        <div className="flex-1">
          <label className="block text-[10px] text-slate-500 mb-1">الرقم التعريفي</label>
          <input
            value={numericId}
            onChange={e => setNumericId(e.target.value)}
            placeholder="مثل: 445764"
            className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600"
            onKeyDown={e => e.key === 'Enter' && handleOpen()}
          />
        </div>
        <div>
          <label className="block text-[10px] text-slate-500 mb-1">نوع الوكالة</label>
          <select
            value={agencyType}
            onChange={e => setAgencyType(e.target.value)}
            className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500"
          >
            <option value="shipping">شحن ماس</option>
            <option value="hosting">استضافة</option>
            <option value="mixed">مختلط</option>
          </select>
        </div>
        <button
          onClick={handleOpen}
          disabled={loading || !numericId.trim()}
          className="text-xs bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-white px-4 py-1.5 rounded-lg font-semibold transition-colors whitespace-nowrap"
        >
          {loading ? 'جاري...' : 'فتح الوكالة'}
        </button>
      </div>
      {result && (
        <div className={`mt-3 p-3 rounded-lg text-xs ${result.ok ? 'bg-emerald-500/10 text-emerald-400' : 'bg-rose-500/10 text-rose-400'}`}>
          {result.ok ? (
            <div className="space-y-1">
              <p className="font-semibold">تم فتح الوكالة بنجاح!</p>
              <p>رقم الوكالة: <span className="text-white font-mono">{result.agency_id}</span></p>
              <p>البريد: <span className="text-white font-mono">{result.email}</span></p>
              <p>كلمة المرور: <span className="text-white font-mono">{result.password}</span></p>
              <button
                onClick={() => {
                  window.open(`${AGENCY_DASH_URL}#agency_id=${result.agency_id}&email=${result.email}&password=${result.password}`, '_blank');
                }}
                className="mt-2 text-xs bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-1.5 rounded-lg font-semibold"
              >
                فتح لوحة تحكم الوكالة
              </button>
            </div>
          ) : (
            <p>{result.error}</p>
          )}
        </div>
      )}
    </div>
  );
}

/* =============================================================
   AGENCY MEMBERS PANEL (inline in agencies tab)
   ============================================================= */
function AgencyMembersPanel({ agencyId }: { agencyId: string }) {
  const [members, setMembers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    supabase.from('host_agency_members').select('*').eq('agency_id', agencyId)
      .then(({ data }) => { setMembers(data || []); setLoading(false); });
  }, [agencyId]);

  if (loading) return <div className="bg-[#141417] rounded-2xl border border-white/5 p-4 mt-3 text-xs text-slate-500">جاري تحميل الأعضاء...</div>;

  return (
    <div className="bg-[#141417] rounded-2xl border border-cyan-500/20 p-4 mt-3">
      <p className="text-cyan-400 text-xs font-semibold mb-3">أعضاء الوكالة ({members.length})</p>
      {members.length === 0 ? (
        <p className="text-slate-600 text-[10px]">لا يوجد أعضاء</p>
      ) : (
        <div className="space-y-2">
          {members.map(m => (
            <div key={`${m.agency_id}-${m.user_id}`} className="flex items-center justify-between bg-[#161618] rounded-lg px-3 py-2">
              <div className="flex items-center gap-2">
                <span className="text-white text-xs font-semibold">{m.user_name || m.user_id}</span>
                <span className={`text-[10px] px-2 py-0.5 rounded-full ${
                  m.role === 'owner' ? 'text-amber-400 bg-amber-400/10' :
                  m.role === 'supervisor' ? 'text-cyan-400 bg-cyan-400/10' :
                  'text-indigo-400 bg-indigo-400/10'
                }`}>{m.role}</span>
                <span className={`text-[10px] ${m.status === 'active' ? 'text-emerald-400' : 'text-slate-500'}`}>{m.status}</span>
              </div>
              <span className="text-[10px] text-slate-500">{new Date(m.joined_at).toLocaleDateString('ar')}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

/* =============================================================
   2. MEMBERS TAB
   ============================================================= */
function MembersTab() {
  const { t } = useContext(I18nContext);
  const [members, setMembers] = useState<HostAgencyMemberModel[]>([]);
  const [agencies, setAgencies] = useState<HostAgencyModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterAgency, setFilterAgency] = useState('');

  const load = async () => {
    setLoading(true);
    const [m, a] = await Promise.all([getHostAgencyMembers(filterAgency || undefined), getHostAgencies()]);
    setMembers(m); setAgencies(a); setLoading(false);
  };
  useEffect(() => { load(); }, [filterAgency]);

  const handleRoleChange = async (agencyId: string, userId: string, role: string) => {
    await updateAgencyMemberRole(agencyId, userId, role);
    load();
  };

  const handleRemove = async (agencyId: string, userId: string) => {
    if (confirm(t('agency.removeMemberConfirm'))) {
      await removeAgencyMember(agencyId, userId);
      load();
    }
  };

  const roleColors: Record<string, string> = {
    owner: 'text-amber-400 bg-amber-400/10',
    supervisor: 'text-cyan-400 bg-cyan-400/10',
    host: 'text-indigo-400 bg-indigo-400/10',
  };

  return (
    <div>
      <div className="flex items-center gap-3 mb-3">
        <p className="text-slate-500 text-xs">{members.length} {t('agency.membersCount')}</p>
        <select value={filterAgency} onChange={e => setFilterAgency(e.target.value)}
          className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
          <option value="">{t('agency.filterAgency')}</option>
          {agencies.map(a => <option key={a.id} value={a.id}>{a.name}</option>)}
        </select>
      </div>
      <DataTable
        loading={loading}
        columns={[
          { key: 'user_name', label: t('agency.col.name'), sortable: true },
          { key: 'agency_id', label: t('agency.col.name'), sortable: true, render: m => {
            const member = m as HostAgencyMemberModel;
            const agency = agencies.find(a => a.id === member.agency_id);
            return <span className="text-slate-300">{agency?.name ?? (member.agency_id?.slice(0, 8) ?? '')}</span>;
          }},
          { key: 'role', label: t('agency.col.role'), sortable: true, render: m => {
            const member = m as HostAgencyMemberModel;
            const roleT = t(`agency.${member.role}` as any);
            return <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${roleColors[member.role] ?? 'text-slate-400'}`}>{roleT}</span>;
          }},
          { key: 'status', label: t('agency.col.status'), sortable: true, render: m => {
            const st = (m as HostAgencyMemberModel).status;
            return <span className={st === 'active' ? 'text-emerald-400' : 'text-slate-500'}>{st}</span>;
          }},
          { key: 'diamonds_earned_monthly', label: t('agency.col.monthlyDiamonds'), sortable: true, render: m => {
            const v = (m as HostAgencyMemberModel).diamonds_earned_monthly;
            return <span className="text-amber-400">{v?.toLocaleString() ?? '0'}</span>;
          }},
          { key: 'diamonds_balance', label: t('agency.col.balance'), sortable: true, render: m => {
            const v = (m as HostAgencyMemberModel).diamonds_balance;
            return <span className="text-cyan-400">{v?.toLocaleString() ?? '0'}</span>;
          }},
          { key: 'joined_at', label: t('agency.col.joined'), sortable: true, render: m => new Date((m as HostAgencyMemberModel).joined_at).toLocaleDateString() },
          { key: 'actions', label: t('agency.col.actions'), render: m => {
            const member = m as HostAgencyMemberModel;
            if (member.role === 'owner') return <span className="text-[10px] text-slate-500">—</span>;
            return (
              <div className="flex items-center gap-2">
                <select defaultValue="" onChange={e => { if (e.target.value) handleRoleChange(member.agency_id, member.user_id, e.target.value); }}
                  className="bg-[#161618] border border-white/10 rounded py-0.5 px-1 text-[10px] text-white">
                  <option value="" disabled>{t('agency.roleChange')}</option>
                  <option value="supervisor">{t('agency.supervisor')}</option>
                  <option value="host">{t('agency.host')}</option>
                </select>
                <button onClick={() => handleRemove(member.agency_id, member.user_id)}
                  className="text-[10px] text-rose-400 hover:text-rose-300 font-semibold">{t('agency.remove')}</button>
              </div>
            );
          }},
        ]}
        data={members}
        searchKeys={['user_name', 'role', 'status']}
      />
    </div>
  );
}

/* =============================================================
   3. JOIN REQUESTS TAB
   ============================================================= */
function JoinRequestsTab() {
  const { t } = useContext(I18nContext);
  const [requests, setRequests] = useState<AgencyJoinRequestModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('pending');

  const load = () => { setLoading(true); getHostAgencyJoinRequests(filter).then(d => { setRequests(d); setLoading(false); }); };
  useEffect(() => { load(); }, [filter]);

  const statusColors: Record<string, string> = {
    pending: 'text-yellow-400', approved: 'text-emerald-400', rejected: 'text-rose-400',
  };

  return (
    <div>
      <div className="flex items-center gap-3 mb-3">
        <p className="text-slate-500 text-xs">{requests.length} {t('agency.requestsCount')}</p>
        <select value={filter} onChange={e => setFilter(e.target.value)}
          className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
          <option value="pending">{t('agency.pending')}</option>
          <option value="approved">{t('agency.approved')}</option>
          <option value="rejected">{t('agency.rejected')}</option>
          <option value="">{t('agency.all')}</option>
        </select>
      </div>
      <DataTable
        loading={loading}
        columns={[
          { key: 'user_name', label: t('agency.col.name'), sortable: true },
          { key: 'agency_name', label: t('agency.col.name'), sortable: true },
          { key: 'status', label: t('agency.col.status'), sortable: true, render: r => {
            const st = (r as AgencyJoinRequestModel).status;
            return <span className={`font-semibold ${statusColors[st] ?? 'text-slate-400'}`}>{t(`agency.${st}` as any)}</span>;
          }},
          { key: 'created_at', label: t('agency.col.date'), sortable: true, render: r => new Date((r as AgencyJoinRequestModel).created_at).toLocaleDateString() },
          { key: 'actions', label: t('agency.col.actions'), render: r => {
            const req = r as AgencyJoinRequestModel;
            if (req.status !== 'pending') return <span className="text-[10px] text-slate-500">—</span>;
            return (
              <div className="flex items-center gap-2">
                <button onClick={async () => { await approveJoinRequest(req.id); load(); }}
                  className="text-[10px] bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30 px-2 py-0.5 rounded font-semibold">{t('agency.approve')}</button>
                <button onClick={async () => { await rejectJoinRequest(req.id); load(); }}
                  className="text-[10px] bg-rose-500/20 text-rose-400 hover:bg-rose-500/30 px-2 py-0.5 rounded font-semibold">{t('agency.reject')}</button>
              </div>
            );
          }},
        ]}
        data={requests}
        searchKeys={['user_name', 'agency_name', 'status']}
      />
    </div>
  );
}

/* =============================================================
   4. FINANCIAL TAB (Ledger + Withdrawals)
   ============================================================= */
function FinancialTab() {
  const { t } = useContext(I18nContext);
  const [subTab, setSubTab] = useState<'ledger' | 'withdrawals'>('ledger');
  const [ledger, setLedger] = useState<AgencyLedgerEntryModel[]>([]);
  const [withdrawals, setWithdrawals] = useState<AgencyWithdrawalRequestModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [wFilter, setWFilter] = useState('pending');

  const loadLedger = () => { getAgencyLedger().then(d => setLedger(d)); };
  const loadWithdrawals = () => { setLoading(true); getWithdrawalRequests(wFilter).then(d => { setWithdrawals(d); setLoading(false); }); };

  useEffect(() => { loadLedger(); }, []);
  useEffect(() => { loadWithdrawals(); }, [wFilter]);

  const statusColors: Record<string, string> = {
    pending: 'text-yellow-400', approved: 'text-emerald-400', rejected: 'text-rose-400',
  };

  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        <button onClick={() => setSubTab('ledger')}
          className={`text-xs px-3 py-1.5 rounded-lg font-semibold transition-colors ${subTab === 'ledger' ? 'bg-indigo-500/20 text-indigo-300' : 'text-slate-400 hover:text-white'}`}>
          {t('agency.diamondLedger')}
        </button>
        <button onClick={() => setSubTab('withdrawals')}
          className={`text-xs px-3 py-1.5 rounded-lg font-semibold transition-colors ${subTab === 'withdrawals' ? 'bg-indigo-500/20 text-indigo-300' : 'text-slate-400 hover:text-white'}`}>
          {t('agency.withdrawalRequests')}
        </button>
      </div>

      {subTab === 'ledger' && (
        <div>
          <p className="text-slate-500 text-xs mb-3">{ledger.length} {t('agency.entriesCount')}</p>
          <DataTable
            loading={false}
            columns={[
              { key: 'user_name', label: t('agency.col.name'), sortable: true },
              { key: 'agency_name', label: t('agency.col.name'), sortable: true },
              { key: 'txn_type', label: t('agency.col.type'), sortable: true, render: e => <span className="text-indigo-300">{(e as AgencyLedgerEntryModel).txn_type}</span> },
              { key: 'amount', label: t('agency.col.amount'), sortable: true, render: e => {
                const entry = e as AgencyLedgerEntryModel;
                return <span className={entry.direction === 'in' ? 'text-emerald-400' : 'text-rose-400'}>
                  {entry.direction === 'in' ? '+' : '-'}{entry.amount?.toLocaleString() ?? '0'} 💎
                </span>;
              }},
              { key: 'balance_after', label: t('agency.col.balance'), sortable: true, render: e => <span className="text-cyan-400">{(e as AgencyLedgerEntryModel).balance_after?.toLocaleString() ?? '0'}</span> },
              { key: 'note', label: t('agency.col.note'), render: e => <span className="text-slate-500">{(e as AgencyLedgerEntryModel).note ?? '—'}</span> },
              { key: 'created_at', label: t('agency.col.date'), sortable: true, render: e => new Date((e as AgencyLedgerEntryModel).created_at).toLocaleDateString() },
            ]}
            data={ledger}
            searchKeys={['user_name', 'agency_name', 'txn_type', 'note']}
          />
        </div>
      )}

      {subTab === 'withdrawals' && (
        <div>
          <div className="flex items-center gap-3 mb-3">
            <p className="text-slate-500 text-xs">{withdrawals.length} {t('agency.requestsCount')}</p>
            <select value={wFilter} onChange={e => setWFilter(e.target.value)}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
              <option value="pending">{t('agency.pending')}</option>
              <option value="approved">{t('agency.approved')}</option>
              <option value="rejected">{t('agency.rejected')}</option>
              <option value="">{t('agency.all')}</option>
            </select>
          </div>
          <DataTable
            loading={loading}
            columns={[
              { key: 'user_name', label: t('agency.col.name'), sortable: true },
              { key: 'agency_name', label: t('agency.col.name'), sortable: true },
              { key: 'amount', label: t('agency.col.amount'), sortable: true, render: w => <span className="text-amber-400 font-semibold">{(w as AgencyWithdrawalRequestModel).amount?.toLocaleString() ?? '0'} 💎</span> },
              { key: 'status', label: t('agency.col.status'), sortable: true, render: w => {
                const st = (w as AgencyWithdrawalRequestModel).status;
                return <span className={`font-semibold ${statusColors[st] ?? 'text-slate-400'}`}>{t(`agency.${st}` as any)}</span>;
              }},
              { key: 'payment_method', label: t('agency.col.payment'), render: w => <span className="text-slate-400">{(w as AgencyWithdrawalRequestModel).payment_method ?? '—'}</span> },
              { key: 'created_at', label: t('agency.col.date'), sortable: true, render: w => new Date((w as AgencyWithdrawalRequestModel).created_at).toLocaleDateString() },
              { key: 'actions', label: t('agency.col.actions'), render: w => {
                const req = w as AgencyWithdrawalRequestModel;
                if (req.status !== 'pending') return <span className="text-[10px] text-slate-500">—</span>;
                return (
                  <div className="flex items-center gap-2">
                    <button onClick={async () => { await approveWithdrawal(req.id); loadWithdrawals(); }}
                      className="text-[10px] bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30 px-2 py-0.5 rounded font-semibold">{t('agency.approve')}</button>
                    <button onClick={async () => { await rejectWithdrawal(req.id); loadWithdrawals(); }}
                      className="text-[10px] bg-rose-500/20 text-rose-400 hover:bg-rose-500/30 px-2 py-0.5 rounded font-semibold">{t('agency.reject')}</button>
                  </div>
                );
              }},
            ]}
            data={withdrawals}
            searchKeys={['user_name', 'agency_name', 'status', 'payment_method']}
          />
        </div>
      )}
    </div>
  );
}

/* =============================================================
   5. MILESTONES TAB
   ============================================================= */
function MilestonesTab() {
  const { t } = useContext(I18nContext);
  const [milestones, setMilestones] = useState<HostMilestoneModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [title, setTitle] = useState('');
  const [targetDiamonds, setTargetDiamonds] = useState('1000');
  const [rewardType, setRewardType] = useState('gold');
  const [rewardValue, setRewardValue] = useState('100');
  const [rewardItemId, setRewardItemId] = useState('');
  const [periodType, setPeriodType] = useState('monthly');
  const [sortOrder, setSortOrder] = useState('0');

  const load = () => { setLoading(true); getHostMilestones().then(d => { setMilestones(d); setLoading(false); }); };
  useEffect(() => { load(); }, []);

  const resetForm = () => {
    setTitle(''); setTargetDiamonds('1000'); setRewardType('gold');
    setRewardValue('100'); setRewardItemId(''); setPeriodType('monthly'); setSortOrder('0');
  };

  const handleCreate = async () => {
    if (!title.trim()) return;
    await createHostMilestone({
      title: title.trim(), target_diamonds: parseInt(targetDiamonds) || 0,
      reward_type: rewardType as HostMilestoneModel['reward_type'],
      reward_value: parseInt(rewardValue) || 0, reward_item_id: rewardItemId.trim() || null,
      period_type: periodType as HostMilestoneModel['period_type'],
      is_active: true, sort_order: parseInt(sortOrder) || 0,
    });
    resetForm(); setShowForm(false); load();
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-3">
        <p className="text-slate-500 text-xs">{milestones.length} {t('agency.milestones')}</p>
        <button onClick={() => { resetForm(); setShowForm(!showForm); }}
          className="text-xs bg-indigo-500 hover:bg-indigo-600 text-white px-3 py-1.5 rounded-lg font-semibold transition-colors">
          {showForm ? t('cancel') : t('agency.newMilestone')}
        </button>
      </div>
      {showForm && (
        <div className="bg-[#141417] rounded-2xl border border-white/5 p-4 mb-4 space-y-3">
          <div className="grid grid-cols-3 gap-3">
            <input value={title} onChange={e => setTitle(e.target.value)} placeholder={t('agency.milestone.title')}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
            <input type="number" value={targetDiamonds} onChange={e => setTargetDiamonds(e.target.value)} placeholder={t('agency.milestone.target')}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
            <input type="number" value={rewardValue} onChange={e => setRewardValue(e.target.value)} placeholder={t('agency.milestone.rewardValue')}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
          </div>
          <div className="grid grid-cols-3 gap-3">
            <select value={rewardType} onChange={e => setRewardType(e.target.value)}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
              <option value="gold">Gold</option><option value="diamonds">Diamonds</option>
              <option value="vip_days">VIP Days</option><option value="badge">Badge</option>
              <option value="gift_item">Gift Item</option>
            </select>
            <select value={periodType} onChange={e => setPeriodType(e.target.value)}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
              <option value="monthly">Monthly</option><option value="weekly">Weekly</option>
              <option value="all_time">All Time</option>
            </select>
            <input type="number" value={sortOrder} onChange={e => setSortOrder(e.target.value)} placeholder={t('agency.milestone.sortOrder')}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
          </div>
          <input value={rewardItemId} onChange={e => setRewardItemId(e.target.value)} placeholder={t('agency.milestone.rewardItemId')}
            className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
          <button onClick={handleCreate}
            className="text-xs bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-1.5 rounded-lg font-semibold transition-colors">
            {t('agency.createMilestone')}
          </button>
        </div>
      )}
      <DataTable
        loading={loading}
        columns={[
          { key: 'title', label: t('agency.col.name'), sortable: true },
          { key: 'target_diamonds', label: t('agency.milestone.target'), sortable: true, render: m => <span className="text-cyan-400">{(m as HostMilestoneModel).target_diamonds?.toLocaleString() ?? '0'}</span> },
          { key: 'reward_type', label: t('agency.col.rewardType'), sortable: true, render: m => <span className="text-amber-400">{(m as HostMilestoneModel).reward_type}</span> },
          { key: 'reward_value', label: t('agency.col.rewardValue'), sortable: true },
          { key: 'period_type', label: t('agency.col.period'), sortable: true, render: m => <span className="text-slate-400">{(m as HostMilestoneModel).period_type}</span> },
          { key: 'sort_order', label: t('agency.col.order'), sortable: true },
          { key: 'is_active', label: t('agency.col.active'), sortable: true, render: m => {
            const active = (m as HostMilestoneModel).is_active;
            return <span className={active ? 'text-emerald-400' : 'text-rose-400'}>{active ? t('agency.yes') : t('agency.no')}</span>;
          }},
        ]}
        data={milestones}
        searchKeys={['title', 'reward_type', 'period_type']}
        onEdit={async m => {
          const mi = m as HostMilestoneModel;
          await updateHostMilestone(mi.id, { is_active: !mi.is_active });
          load();
        }}
        onDelete={async m => {
          if (confirm(t('agency.deleteMilestoneConfirm'))) { await deleteHostMilestone((m as HostMilestoneModel).id); load(); }
        }}
      />
    </div>
  );
}

/* =============================================================
   6. COMMISSION TAB
   ============================================================= */
function CommissionTab() {
  const { t } = useContext(I18nContext);
  const [settings, setSettings] = useState<CommissionSettingModel[]>([]);
  const [loading, setLoading] = useState(true);

  const load = () => { setLoading(true); getCommissionSettings().then(d => { setSettings(d); setLoading(false); }); };
  useEffect(() => { load(); }, []);

  const handleUpdate = async (id: string, value: number) => {
    await updateCommissionSetting(id, value);
    load();
  };

  const descKeyMap: Record<string, string> = {
    host_rate: 'agency.commission.hostRate',
    agency_rate: 'agency.commission.agencyRate',
    platform_rate: 'agency.commission.platformRate',
    gold_to_diamond: 'agency.commission.goldToDiamond',
    diamonds_per_usd: 'agency.commission.diamondsPerUsd',
  };

  return (
    <div>
      <p className="text-slate-500 text-xs mb-3">{t('agency.commission')}</p>
      <div className="bg-[#141417] rounded-2xl border border-white/5 overflow-hidden">
        <table className="w-full text-xs">
          <thead>
            <tr className="border-b border-white/5">
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">{t('agency.col.key')}</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">{t('agency.col.desc')}</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">{t('agency.col.value')}</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">{t('agency.col.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={4} className="text-center py-12 text-slate-500">{t('agency.loading')}</td></tr>
            ) : settings.map(s => (
              <tr key={s.id} className="border-b border-white/5 hover:bg-white/5">
                <td className="p-3 text-white font-mono">{s.key}</td>
                <td className="p-3 text-slate-400">{t(descKeyMap[s.key] as any) || s.description}</td>
                <td className="p-3"><span className="text-amber-400 font-semibold">{s.value}</span></td>
                <td className="p-3">
                  <InlineEdit value={s.value} onSave={v => handleUpdate(s.id, v)} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function InlineEdit({ value, onSave }: { value: number; onSave: (v: number) => void }) {
  const { t } = useContext(I18nContext);
  const [editing, setEditing] = useState(false);
  const [val, setVal] = useState(value != null ? String(value) : '0');
  if (!editing) return (
    <button onClick={() => { setVal(value != null ? String(value) : '0'); setEditing(true); }}
      className="text-[10px] text-indigo-400 hover:text-indigo-300 font-semibold">{t('edit')}</button>
  );
  return (
    <div className="flex items-center gap-1">
      <input type="number" step="0.01" value={val} onChange={e => setVal(e.target.value)}
        className="w-20 bg-[#161618] border border-white/10 rounded py-1 px-2 text-xs text-white" autoFocus
        onKeyDown={e => { if (e.key === 'Enter') { onSave(parseFloat(val) || 0); setEditing(false); } if (e.key === 'Escape') setEditing(false); }} />
      <button onClick={() => { onSave(parseFloat(val) || 0); setEditing(false); }}
        className="text-[10px] text-emerald-400 font-semibold">{t('save')}</button>
      <button onClick={() => setEditing(false)}
        className="text-[10px] text-slate-500 font-semibold">X</button>
    </div>
  );
}

/* =============================================================
   GIFT COMMISSION TAB - Global settings for gift commission
   ============================================================= */
function GiftCommissionTab() {
  const { t } = useContext(I18nContext);
  const [settings, setSettings] = useState<CommissionSettingModel[]>([]);
  const [loading, setLoading] = useState(true);

  const load = () => {
    setLoading(true);
    getCommissionSettings().then(d => {
      setSettings(d.filter(s => ['gift_commission_percent', 'gift_entry_percent', 'host_profit_percent'].includes(s.key)));
      setLoading(false);
    });
  };
  useEffect(() => { load(); }, []);

  const handleUpdate = async (id: string, value: number) => {
    await updateCommissionSetting(id, value);
    load();
  };

  const descMap: Record<string, string> = {
    gift_commission_percent: 'نسبة عمولة الوكالة من الهدايا (0-100%)',
    gift_entry_percent: 'نسبة دخول قيمة الهدية في نظام المكافآت (0-100%)',
    host_profit_percent: 'نسبة أرباح المضيف من الهدايا (0-100%)',
  };

  return (
    <div className="space-y-4">
      <p className="text-slate-400 text-xs">إعداد عمولة الهدايا - تحديد النسب المئوية لعمولة الوكالة وأرباح المضيف</p>
      <div className="bg-[#141417] rounded-2xl border border-white/5 overflow-hidden">
        <table className="w-full text-xs">
          <thead>
            <tr className="border-b border-white/5">
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">المفتاح</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">الوصف</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">القيمة (%)</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">الإجراءات</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={4} className="text-center py-12 text-slate-500">جاري التحميل...</td></tr>
            ) : settings.length === 0 ? (
              <tr><td colSpan={4} className="text-center py-12 text-slate-500">لا توجد إعدادات. شغّل SQL أولاً.</td></tr>
            ) : settings.map(s => (
              <tr key={s.id} className="border-b border-white/5 hover:bg-white/5">
                <td className="p-3 text-white font-mono">{s.key}</td>
                <td className="p-3 text-slate-400">{descMap[s.key] || s.description}</td>
                <td className="p-3"><span className="text-amber-400 font-semibold">{s.value}%</span></td>
                <td className="p-3">
                  <InlineEdit value={s.value} onSave={v => handleUpdate(s.id, Math.min(100, Math.max(0, v)))} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* =============================================================
   PROFIT LEVELS TAB - Host profit levels based on earnings
   ============================================================= */
interface ProfitLevel {
  id: string;
  level_name: string;
  min_cumulative_coins: number;
  profit_percent: number;
  target: number;
  period_type: string;
  sort_order: number;
  is_active: boolean;
}

function ProfitLevelsTab() {
  const [levels, setLevels] = useState<ProfitLevel[]>([]);
  const [loading, setLoading] = useState(true);
  const [edit, setEdit] = useState<ProfitLevel | null>(null);

  const load = async () => {
    setLoading(true);
    const { data } = await supabase.from('host_profit_levels').select('*').order('sort_order');
    setLevels((data as ProfitLevel[]) || []);
    setLoading(false);
  };
  useEffect(() => { load(); }, []);

  const handleSave = async (level: ProfitLevel) => {
    await supabase.from('host_profit_levels').upsert({
      id: level.id, level_name: level.level_name,
      min_cumulative_coins: level.min_cumulative_coins,
      profit_percent: level.profit_percent,
      target: level.target,
      period_type: level.period_type,
      sort_order: level.sort_order, is_active: level.is_active,
    }, { onConflict: 'id' });
    setEdit(null);
    load();
  };

  const handleCreate = async () => {
    const newLevel: ProfitLevel = {
      id: crypto.randomUUID(),
      level_name: 'مستوى جديد',
      min_cumulative_coins: 0,
      profit_percent: 50,
      target: 5000,
      period_type: 'weekly',
      sort_order: levels.length + 1,
      is_active: true,
    };
    await supabase.from('host_profit_levels').insert(newLevel);
    load();
  };

  const handleDelete = async (id: string) => {
    if (confirm('هل أنت متأكد من حذف هذا المستوى؟')) {
      await supabase.from('host_profit_levels').delete().eq('id', id);
      load();
    }
  };

  if (loading) return <p className="text-slate-500 text-xs">جاري التحميل...</p>;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-slate-400 text-xs">مستويات أرباح المضيف - تحديد نسبة الربح لكل مستوى بناءً على الأرباح التراكمية</p>
        <button onClick={handleCreate}
          className="text-xs bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-1.5 rounded-lg font-semibold transition-colors">
          + إضافة مستوى
        </button>
      </div>
      <div className="bg-[#141417] rounded-2xl border border-white/5 overflow-hidden">
        <table className="w-full text-xs">
          <thead>
            <tr className="border-b border-white/5">
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">اسم المستوى</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">الحد الأدنى (كوينز)</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">نسبة الربح (%)</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">الهدف</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">الفترة</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">الترتيب</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">نشط</th>
              <th className="text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {levels.map(lv => (
              <tr key={lv.id} className="border-b border-white/5 hover:bg-white/5">
                {edit?.id === lv.id ? (
                  <>
                    <td className="p-2"><input value={edit.level_name} onChange={e => setEdit({ ...edit, level_name: e.target.value })}
                      className="w-full bg-[#161618] border border-white/10 rounded py-1 px-2 text-xs text-white" /></td>
                    <td className="p-2"><input type="number" value={edit.min_cumulative_coins} onChange={e => setEdit({ ...edit, min_cumulative_coins: parseInt(e.target.value) || 0 })}
                      className="w-full bg-[#161618] border border-white/10 rounded py-1 px-2 text-xs text-white" /></td>
                    <td className="p-2"><input type="number" value={edit.profit_percent} onChange={e => setEdit({ ...edit, profit_percent: parseInt(e.target.value) || 0 })}
                      className="w-full bg-[#161618] border border-white/10 rounded py-1 px-2 text-xs text-white" /></td>
                    <td className="p-2"><input type="number" value={edit.target} onChange={e => setEdit({ ...edit, target: parseInt(e.target.value) || 0 })}
                      className="w-full bg-[#161618] border border-white/10 rounded py-1 px-2 text-xs text-white" /></td>
                    <td className="p-2">
                      <select value={edit.period_type} onChange={e => setEdit({ ...edit, period_type: e.target.value })}
                        className="w-full bg-[#161618] border border-white/10 rounded py-1 px-2 text-xs text-white">
                        <option value="weekly">أسبوعي</option>
                        <option value="monthly">شهري</option>
                        <option value="all_time">دائم</option>
                      </select>
                    </td>
                    <td className="p-2"><input type="number" value={edit.sort_order} onChange={e => setEdit({ ...edit, sort_order: parseInt(e.target.value) || 0 })}
                      className="w-full bg-[#161618] border border-white/10 rounded py-1 px-2 text-xs text-white" /></td>
                    <td className="p-2">
                      <button onClick={() => handleSave(edit)} className="text-emerald-400 font-semibold text-[10px]">حفظ</button>
                      <button onClick={() => setEdit(null)} className="text-slate-500 font-semibold text-[10px] ml-2">إلغاء</button>
                    </td>
                    <td className="p-2"></td>
                  </>
                ) : (
                  <>
                    <td className="p-3 text-white font-semibold">{lv.level_name}</td>
                    <td className="p-3 text-cyan-400">{lv.min_cumulative_coins.toLocaleString()}</td>
                    <td className="p-3 text-amber-400">{lv.profit_percent}%</td>
                    <td className="p-3 text-cyan-300">{(lv.target ?? 0).toLocaleString()}</td>
                    <td className="p-3 text-slate-400">{lv.period_type || 'weekly'}</td>
                    <td className="p-3 text-slate-400">{lv.sort_order}</td>
                    <td className="p-3">
                      <span className={lv.is_active ? 'text-emerald-400' : 'text-rose-400'}>
                        {lv.is_active ? 'نشط' : 'معطل'}
                      </span>
                    </td>
                    <td className="p-3 flex gap-2">
                      <button onClick={() => setEdit(lv)} className="text-indigo-400 text-[10px] font-semibold">تعديل</button>
                      <button onClick={() => handleDelete(lv.id)} className="text-rose-400 text-[10px] font-semibold">حذف</button>
                    </td>
                  </>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* =============================================================
   PAYMENT GATEWAYS TAB
   ============================================================= */
interface GatewayRow {
  id: string;
  name: string;
  name_ar: string;
  type: string;
  is_active: boolean;
  account_number: string;
  account_name: string;
  bank_name: string;
  wallet_address: string;
  instructions: string;
  instructions_ar: string;
  sort_order: number;
}

function PaymentGatewaysTab() {
  const [gateways, setGateways] = useState<GatewayRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [edit, setEdit] = useState<GatewayRow | null>(null);

  const load = async () => {
    setLoading(true);
    const { data } = await supabase.from('payment_gateways').select('*').order('sort_order');
    setGateways((data as GatewayRow[]) || []);
    setLoading(false);
  };
  useEffect(() => { load(); }, []);

  const handleSave = async (gw: GatewayRow) => {
    await supabase.from('payment_gateways').upsert({
      id: gw.id, name: gw.name, name_ar: gw.name_ar, type: gw.type,
      is_active: gw.is_active, account_number: gw.account_number || '',
      account_name: gw.account_name || '', bank_name: gw.bank_name || '',
      wallet_address: gw.wallet_address || '', instructions: gw.instructions || '',
      instructions_ar: gw.instructions_ar || '', sort_order: gw.sort_order ?? 0,
    }, { onConflict: 'id' });
    setEdit(null);
    load();
  };

  const typeLabels: Record<string, string> = {
    vodafone_cash: 'فودافون كاش', etisalat_cash: 'اتصالات كاش',
    syriatel_cash: 'سيرياتيل كاش', usdt_trc20: 'USDT (TRC20)', bank_transfer: 'تحويل بنكي',
  };

  if (loading) return <p className="text-slate-500 text-xs">جاري التحميل...</p>;

  return (
    <div className="space-y-4">
      <p className="text-slate-400 text-xs">إعداد بوابتات الدفع لشحن الوكالات</p>
      <div className="space-y-3">
        {gateways.map(gw => (
          <div key={gw.id} className="bg-[#141417] rounded-xl border border-white/5 p-4">
            {edit?.id === gw.id ? (
              <div className="space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[10px] text-slate-500 mb-1">الاسم بالعربي</label>
                    <input value={edit.name_ar} onChange={e => setEdit({ ...edit, name_ar: e.target.value })}
                      className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500" />
                  </div>
                  <div>
                    <label className="block text-[10px] text-slate-500 mb-1">الاسم بالإنجليزي</label>
                    <input value={edit.name} onChange={e => setEdit({ ...edit, name: e.target.value })}
                      className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[10px] text-slate-500 mb-1">رقم الحساب / المحفظة</label>
                    <input value={edit.account_number || edit.wallet_address || ''} onChange={e => {
                      if (edit.type === 'usdt_trc20') setEdit({ ...edit, wallet_address: e.target.value });
                      else setEdit({ ...edit, account_number: e.target.value });
                    }}
                      className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500" />
                  </div>
                  <div>
                    <label className="block text-[10px] text-slate-500 mb-1">اسم صاحب الحساب</label>
                    <input value={edit.account_name || ''} onChange={e => setEdit({ ...edit, account_name: e.target.value })}
                      className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500" />
                  </div>
                </div>
                {edit.type === 'bank_transfer' && (
                  <div>
                    <label className="block text-[10px] text-slate-500 mb-1">اسم البنك</label>
                    <input value={edit.bank_name || ''} onChange={e => setEdit({ ...edit, bank_name: e.target.value })}
                      className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500" />
                  </div>
                )}
                <div>
                  <label className="block text-[10px] text-slate-500 mb-1">تعليمات الدفع (عربي)</label>
                  <textarea value={edit.instructions_ar || ''} onChange={e => setEdit({ ...edit, instructions_ar: e.target.value })}
                    rows={3}
                    className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500" />
                </div>
                <div className="flex items-center gap-3">
                  <label className="flex items-center gap-2 text-xs text-slate-400">
                    <input type="checkbox" checked={edit.is_active} onChange={e => setEdit({ ...edit, is_active: e.target.checked })}
                      className="rounded" />
                    مفعّل
                  </label>
                  <div className="flex-1" />
                  <button onClick={() => handleSave(edit)} className="text-xs bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-1.5 rounded-lg font-semibold">حفظ</button>
                  <button onClick={() => setEdit(null)} className="text-xs bg-slate-600 hover:bg-slate-500 text-white px-4 py-1.5 rounded-lg">إلغاء</button>
                </div>
              </div>
            ) : (
              <div className="flex items-center gap-4">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-white text-sm font-semibold">{gw.name_ar}</span>
                    <span className="text-[10px] text-slate-500">{typeLabels[gw.type] || gw.type}</span>
                    <span className={`text-[10px] px-2 py-0.5 rounded-full ${gw.is_active ? 'bg-emerald-500/10 text-emerald-400' : 'bg-rose-500/10 text-rose-400'}`}>
                      {gw.is_active ? 'مفعّل' : 'معطّل'}
                    </span>
                  </div>
                  <p className="text-[10px] text-slate-500 mt-1">{gw.account_number || gw.wallet_address || '—'} {gw.account_name ? `(${gw.account_name})` : ''}</p>
                </div>
                <button onClick={() => setEdit(gw)} className="text-[10px] text-indigo-400 hover:text-indigo-300 font-semibold">تعديل</button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

/* =============================================================
   TOP-UP REQUESTS TAB
   ============================================================= */
interface TopupRequestRow {
  id: string;
  agency_id: string;
  owner_uid: string;
  gateway_id: string;
  amount_usd: number;
  diamonds: number;
  sender_number: string;
  transaction_ref: string;
  status: 'pending' | 'approved' | 'rejected';
  admin_note: string;
  created_at: string;
}

function TopupRequestsTab() {
  const [requests, setRequests] = useState<TopupRequestRow[]>([]);
  const [agencies, setAgencies] = useState<HostAgencyModel[]>([]);
  const [gateways, setGateways] = useState<GatewayRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('pending');
  const [adminTopupAgency, setAdminTopupAgency] = useState('');
  const [adminTopupDiamonds, setAdminTopupDiamonds] = useState('');
  const [topupLoading, setTopupLoading] = useState(false);

  const load = async () => {
    setLoading(true);
    const [reqs, ags, gws] = await Promise.all([
      supabase.from('agency_topup_requests').select('*').order('created_at', { ascending: false }),
      supabase.from('agencies').select('id,name'),
      supabase.from('payment_gateways').select('*'),
    ]);
    setRequests((reqs.data as TopupRequestRow[]) || []);
    setAgencies((ags.data as HostAgencyModel[]) || []);
    setGateways((gws.data as GatewayRow[]) || []);
    setLoading(false);
  };
  useEffect(() => { load(); }, []);

  const filtered = requests.filter(r => filter === 'all' || r.status === filter);

  const handleApprove = async (id: string) => {
    try {
      const result = await adminApi('/api/admin/topup-approve', { request_id: id });
      alert('تمت الموافقة! رصيد ماس الوكالة: ' + (result.diamonds_balance ?? 0).toLocaleString());
      load();
    } catch (e: any) { alert('فشل: ' + e.message); }
  };

  const handleReject = async (id: string) => {
    const note = prompt('سبب الرفض:');
    try {
      await adminApi('/api/admin/topup-reject', { request_id: id, note: note || '' });
      alert('تم الرفض');
      load();
    } catch (e: any) { alert('فشل: ' + e.message); }
  };

  const handleAdminTopup = async () => {
    if (!adminTopupAgency || !adminTopupDiamonds || Number(adminTopupDiamonds) <= 0) return;
    setTopupLoading(true);
    try {
      const diamonds = Number(adminTopupDiamonds);
      const result = await adminApi('/api/admin/topup-direct', { agency_id: adminTopupAgency, diamonds });
      alert('تم الشحن! الرصيد: ' + (result.diamonds_balance ?? 0).toLocaleString());
      setAdminTopupDiamonds('');
    } catch (e: any) { alert('فشل: ' + e.message); }
    setTopupLoading(false);
  };

  const agencyMap = Object.fromEntries(agencies.map(a => [a.id, a.name]));
  const gwMap = Object.fromEntries(gateways.map(g => [g.id, g.name_ar]));
  const statusColors: Record<string, string> = { pending: 'bg-amber-500/10 text-amber-400', approved: 'bg-emerald-500/10 text-emerald-400', rejected: 'bg-rose-500/10 text-rose-400' };
  const statusLabels: Record<string, string> = { pending: 'قيد المراجعة', approved: 'تمت الموافقة', rejected: 'مرفوض' };

  return (
    <div className="space-y-4">
      {/* Admin direct top-up */}
      <div className="bg-[#141417] rounded-xl border border-white/5 p-4">
        <p className="text-white text-xs font-semibold mb-3">شحن مباشر من الإدارة</p>
        <div className="flex gap-2 items-end">
          <div className="flex-1">
            <label className="block text-[10px] text-slate-500 mb-1">الوكالة</label>
            <select value={adminTopupAgency} onChange={e => setAdminTopupAgency(e.target.value)}
              className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white">
              <option value="">اختر وكالة...</option>
              {agencies.map(a => <option key={a.id} value={a.id}>{a.name} ({a.id})</option>)}
            </select>
          </div>
          <div>
            <label className="block text-[10px] text-slate-500 mb-1">عدد الماس</label>
            <input type="number" value={adminTopupDiamonds} onChange={e => setAdminTopupDiamonds(e.target.value)} placeholder="0"
              className="w-32 bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500" />
          </div>
          <button onClick={handleAdminTopup} disabled={topupLoading || !adminTopupAgency || !adminTopupDiamonds}
            className="text-xs bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-white px-4 py-1.5 rounded-lg font-semibold whitespace-nowrap">
            {topupLoading ? 'جاري...' : 'شحن'}
          </button>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-2">
        {['pending', 'approved', 'rejected', 'all'].map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-1.5 text-xs rounded-lg font-semibold transition-colors ${filter === f ? 'bg-indigo-500/20 text-indigo-300' : 'text-slate-400 hover:text-white'}`}>
            {f === 'pending' ? 'قيد المراجعة' : f === 'approved' ? 'تمت الموافقة' : f === 'rejected' ? 'مرفوض' : 'الكل'}
            {f !== 'all' && ` (${requests.filter(r => r.status === f).length})`}
          </button>
        ))}
      </div>

      {/* Requests list */}
      {loading ? <p className="text-slate-500 text-xs">جاري التحميل...</p> : (
        <div className="space-y-2">
          {filtered.length === 0 && <p className="text-slate-600 text-xs">لا توجد طلبات</p>}
          {filtered.map(r => (
            <div key={r.id} className="bg-[#141417] rounded-xl border border-white/5 p-4">
              <div className="flex items-start justify-between">
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="text-white text-xs font-semibold">{agencyMap[r.agency_id] || r.agency_id}</span>
                    <span className={`text-[10px] px-2 py-0.5 rounded-full ${statusColors[r.status]}`}>{statusLabels[r.status]}</span>
                  </div>
                  <p className="text-[10px] text-slate-500">
                    البوابة: {gwMap[r.gateway_id] || r.gateway_id} | المبلغ: ${r.amount_usd} | الماس: {r.diamonds.toLocaleString()}
                  </p>
                  {r.sender_number && <p className="text-[10px] text-slate-500">رقم المرسل: {r.sender_number}</p>}
                  {r.transaction_ref && <p className="text-[10px] text-slate-500">رقم المعاملة: {r.transaction_ref}</p>}
                  <p className="text-[10px] text-slate-600">{new Date(r.created_at).toLocaleString('ar')}</p>
                  {r.admin_note && <p className="text-[10px] text-rose-400">ملاحظة: {r.admin_note}</p>}
                </div>
                {r.status === 'pending' && (
                  <div className="flex gap-2">
                    <button onClick={() => handleApprove(r.id)}
                      className="text-[10px] bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30 px-3 py-1 rounded-lg font-semibold">موافقة</button>
                    <button onClick={() => handleReject(r.id)}
                      className="text-[10px] bg-rose-500/20 text-rose-400 hover:bg-rose-500/30 px-3 py-1 rounded-lg font-semibold">رفض</button>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

/* =============================================================
   OPEN AGENCY REQUESTS TAB - طلبات فتح الوكالات من المستخدمين
   ============================================================= */
function OpenRequestsTab() {
  const [requests, setRequests] = useState<AgencyOpenRequestModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('pending');
  const [rejectNote, setRejectNote] = useState('');
  const [rejectingId, setRejectingId] = useState<string | null>(null);
  const [result, setResult] = useState<{ ok: boolean; msg: string; agency_id?: string; email?: string; password?: string } | null>(null);

  const load = async () => {
    setLoading(true);
    const data = await getAgencyOpenRequests(filter);
    setRequests(data || []);
    setLoading(false);
  };
  useEffect(() => { load(); }, [filter]);

  const handleApprove = async (id: string) => {
    if (!confirm('هل أنت متأكد من الموافقة على فتح هذه الوكالة؟ سيتم إنشاء حساب لوحة التحكم تلقائياً.')) return;
    setResult(null);
    // إزالة الطلب محلياً من القائمة فوراً لعدم ظهوره أثناء انتظار الرد
    setRequests(prev => prev.filter(r => r.id !== id));
    const res = await approveAgencyOpenRequest(id);
    if (res.ok) {
      setResult({
        ok: true,
        msg: '🎉 تمت الموافقة على فتح الوكالة بنجاح! أرسل هذه البيانات للمستخدم:',
        agency_id: res.agency_id,
        email: res.email,
        password: res.password,
      });
    } else {
      // إعادة إضافة الطلب في حال فشل العملية
      load();
      setResult({ ok: false, msg: '❌ فشل الموافقة: ' + (res.error || 'خطأ غير معروف') });
    }
  };

  const openRejectDialog = (id: string) => {
    setRejectingId(id);
    setRejectNote('');
  };

  const handleRejectConfirm = async () => {
    if (!rejectingId) return;
    // إزالة الطلب محلياً أولاً
    const currentRejectingId = rejectingId;
    setRequests(prev => prev.filter(r => r.id !== currentRejectingId));
    setRejectingId(null);
    const res = await rejectAgencyOpenRequest(currentRejectingId, rejectNote);
    if (res.ok) {
      setResult({ ok: true, msg: '✅ تم رفض الطلب بنجاح' });
    } else {
      // فشل: نعيد تحميل القائمة لأصل الحالة
      load();
      setResult({ ok: false, msg: '❌ فشل الرفض: ' + (res.error || 'خطأ غير معروف') });
    }
    setRejectNote('');
  };

  const agencyTypeLabels: Record<string, string> = {
    shipping: 'شحن ماس',
    hosting: 'استضافة',
    mixed: 'مختلط',
  };
  const statusColors: Record<string, string> = {
    pending: 'bg-amber-500/10 text-amber-400',
    approved: 'bg-emerald-500/10 text-emerald-400',
    rejected: 'bg-rose-500/10 text-rose-400',
  };
  const statusLabels: Record<string, string> = {
    pending: 'قيد المراجعة',
    approved: 'تمت الموافقة',
    rejected: 'مرفوض',
  };

  return (
    <div className="space-y-4">
      {result && (
        <div className={`p-3 rounded-lg text-xs border ${result.ok ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400' : 'bg-rose-500/10 border-rose-500/30 text-rose-400'}`}>
          <div className="space-y-1">
            <p className="font-semibold">{result.msg}</p>
            {result.agency_id && (
              <>
                <p>رقم الوكالة: <span className="text-white font-mono">{result.agency_id}</span></p>
                {result.email && <p>البريد: <span className="text-white font-mono">{result.email}</span></p>}
                {result.password && <p>كلمة المرور: <span className="text-white font-mono">{result.password}</span></p>}
              
                 <a href={`${AGENCY_DASH_URL}#agency_id=${result.agency_id}&email=${result.email}&password=${result.password}`} target="_blank" rel="noreferrer"
                   className="mt-2 inline-block text-xs bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-1.5 rounded-lg font-semibold">
                   فتح لوحة تحكم الوكالة ↗
                 </a></>
            )}
          </div>
        </div>
      )}

      <div className="flex items-center gap-3">
        <p className="text-slate-500 text-xs">{requests.length} طلب</p>
        <select value={filter} onChange={e => setFilter(e.target.value)}
          className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
          <option value="pending">قيد المراجعة فقط</option>
          <option value="approved">تمت الموافقة</option>
          <option value="rejected">مرفوض</option>
          <option value="">الكل</option>
        </select>
      </div>

      {rejectingId && (
        <div className="bg-[#141417] rounded-2xl border border-rose-500/30 p-4 space-y-3">
          <p className="text-rose-400 text-xs font-semibold">سبب الرفض (اختياري)</p>
          <textarea value={rejectNote} onChange={e => setRejectNote(e.target.value)}
            placeholder="اكتب سبب الرفض هنا..."
            rows={3}
            className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-rose-500 placeholder:text-slate-600 resize-none" />
          <div className="flex gap-2">
            <button onClick={handleRejectConfirm}
              className="text-xs bg-rose-500 hover:bg-rose-600 text-white px-4 py-1.5 rounded-lg font-semibold">تأكيد الرفض</button>
            <button onClick={() => setRejectingId(null)}
              className="text-xs bg-slate-600 hover:bg-slate-500 text-white px-4 py-1.5 rounded-lg">إلغاء</button>
          </div>
        </div>
      )}

      {loading ? (
        <p className="text-slate-500 text-xs text-center py-12">جاري تحميل الطلبات...</p>
      ) : requests.length === 0 ? (
        <div className="text-center py-16">
          <p className="text-slate-600 text-sm">لا توجد طلبات {filter === 'pending' ? 'قيد المراجعة' : filter === 'approved' ? 'مقبولة' : filter === 'rejected' ? 'مرفوضة' : ''}</p>
        </div>
      ) : (
        <div className="space-y-3">
          {requests.map(r => (
            <div key={r.id} className="bg-[#141417] rounded-2xl border border-white/5 p-4">
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-start gap-3 flex-1">
                  {r.requester?.photo_url ? (
                    <img src={r.requester.photo_url} alt="" className="w-10 h-10 rounded-full object-cover border border-white/20 flex-shrink-0" />
                  ) : (
                    <div className="w-10 h-10 rounded-full bg-indigo-500/30 flex items-center justify-center text-xs text-indigo-300 font-bold flex-shrink-0">
                      {(r.requester?.name || r.agency_name || '?')[0]}
                    </div>
                  )}
                  <div className="space-y-1 flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-white text-sm font-semibold">{r.agency_name}</span>
                      <span className={`text-[10px] px-2 py-0.5 rounded-full ${statusColors[r.status]}`}>{statusLabels[r.status]}</span>
                      {r.agency_type && (
                        <span className="text-[10px] px-2 py-0.5 rounded-full bg-purple-500/10 text-purple-400">
                          {agencyTypeLabels[r.agency_type] || r.agency_type}
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-3 flex-wrap">
                      <p className="text-[11px] text-cyan-400 font-mono">
                        مطلوب من: {r.requester?.numeric_id || r.requester?.name || r.requested_by?.slice(0, 10)}
                      </p>
                      {r.phone && <p className="text-[11px] text-slate-400">📱 {r.phone}</p>}
                    </div>
                    <div className="flex gap-3 mt-2">
                      {r.photo_url && (
                        <a href={r.photo_url} target="_blank" rel="noreferrer" className="text-[10px] text-indigo-400 hover:text-indigo-300">
                          🖼️ صورة شخصية
                        </a>
                      )}
                      {r.id_card_url && (
                        <a href={r.id_card_url} target="_blank" rel="noreferrer" className="text-[10px] text-indigo-400 hover:text-indigo-300">
                          🆔 هوية وطنية
                        </a>
                      )}
                    </div>
                    {r.note && <p className="text-[10px] text-slate-500 mt-1">ملاحظة: {r.note}</p>}
                    <p className="text-[10px] text-slate-600">{new Date(r.created_at).toLocaleString('ar')}</p>
                  </div>
                </div>

                {r.status === 'pending' && !rejectingId && (
                  <div className="flex gap-2 flex-shrink-0">
                    <button onClick={() => handleApprove(r.id)}
                      className="text-[11px] bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30 px-3 py-1.5 rounded-lg font-semibold transition-colors">
                      موافقة وفتح
                    </button>
                    <button onClick={() => openRejectDialog(r.id)}
                      className="text-[11px] bg-rose-500/20 text-rose-400 hover:bg-rose-500/30 px-3 py-1.5 rounded-lg font-semibold transition-colors">
                      رفض
                    </button>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
