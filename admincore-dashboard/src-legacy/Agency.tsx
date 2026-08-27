import { useContext, useEffect, useState } from 'react';
import {
  HostAgencyModel, HostAgencyMemberModel, CommissionSettingModel,
  HostMilestoneModel, AgencyJoinRequestModel, AgencyLedgerEntryModel,
  AgencyWithdrawalRequestModel,
} from '../types';
import {
  getHostAgencies, createHostAgency, updateHostAgency, deleteHostAgency,
  getCommissionSettings, updateCommissionSetting,
  getHostAgencyMembers, getHostMilestones, updateHostMilestone,
  createHostMilestone, deleteHostMilestone,
  getHostAgencyJoinRequests, approveJoinRequest, rejectJoinRequest,
  updateAgencyMemberRole, removeAgencyMember,
  getAgencyLedger, getWithdrawalRequests, approveWithdrawal, rejectWithdrawal,
} from '../lib/db';
import { I18nContext } from '../lib/i18n';
import DataTable from '../components/DataTable';
import { Handshake, Users, UserPlus, Wallet, Target, Settings } from 'lucide-react';

const tabs = [
  { key: 'agencies', labelKey: 'agency.agencies', icon: Handshake },
  { key: 'members', labelKey: 'agency.members', icon: Users },
  { key: 'join_requests', labelKey: 'agency.joinRequests', icon: UserPlus },
  { key: 'financial', labelKey: 'agency.financial', icon: Wallet },
  { key: 'milestones', labelKey: 'agency.milestones', icon: Target },
  { key: 'commission', labelKey: 'agency.commission', icon: Settings },
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
      {tab === 'members' && <MembersTab />}
      {tab === 'join_requests' && <JoinRequestsTab />}
      {tab === 'financial' && <FinancialTab />}
      {tab === 'milestones' && <MilestonesTab />}
      {tab === 'commission' && <CommissionTab />}
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

  const load = () => { setLoading(true); getHostAgencies().then(d => { setAgencies(d); setLoading(false); }); };
  useEffect(() => { load(); }, []);

  const resetForm = () => {
    setName(''); setOwnerId(''); setCommissionRate('5'); setSpecialty('mixed');
    setDescription(''); setCountry(''); setTier('bronze'); setEditId(null);
  };

  const openEdit = (a: HostAgencyModel) => {
    setName(a.name ?? ''); setOwnerId(a.owner_id ?? ''); setCommissionRate(String(a.commission_rate * 100));
    setSpecialty(a.specialty); setDescription(a.description ?? ''); setCountry(a.country ?? '');
    setTier(a.tier ?? 'bronze'); setEditId(a.id); setShowForm(true);
  };

  const handleSubmit = async () => {
    if (!name?.trim() || !ownerId?.trim()) return;
    if (editId) {
      await updateHostAgency(editId, {
        name: name.trim(), owner_id: ownerId.trim(),
        commission_rate: parseInt(commissionRate) / 100,
        specialty, description: description.trim() || null, country: country.trim() || null,
        tier: tier as HostAgencyModel['tier'],
      });
    } else {
      await createHostAgency(name.trim(), ownerId.trim(), parseInt(commissionRate) / 100, specialty);
    }
    resetForm(); setShowForm(false); load();
  };

  const tierColors: Record<string, string> = {
    bronze: 'text-amber-600', silver: 'text-slate-300', gold: 'text-yellow-400',
    platinum: 'text-cyan-300', diamond: 'text-blue-400',
  };

  const tierKey = (v: string) => `agency.tier.${v}` as const;

  return (
    <div>
      <div className="flex items-center justify-between mb-3">
        <p className="text-slate-500 text-xs">{agencies.length} {t('agency.agenciesCount')}</p>
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
            <input value={ownerId} onChange={e => setOwnerId(e.target.value)} placeholder={t('agency.ownerId')}
              className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
            <input value={country} onChange={e => setCountry(e.target.value)} placeholder={t('agency.country')}
              className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
          </div>
          <div className="grid grid-cols-4 gap-3">
            <input type="number" value={commissionRate} onChange={e => setCommissionRate(e.target.value)} placeholder={t('agency.commission')}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
            <select value={specialty} onChange={e => setSpecialty(e.target.value)}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
              <option value="mixed">{t('agency.specialty.mixed')}</option>
              <option value="singing">{t('agency.specialty.singing')}</option>
              <option value="gaming">{t('agency.specialty.gaming')}</option>
              <option value="talk">{t('agency.specialty.talk')}</option>
            </select>
            <select value={tier} onChange={e => setTier(e.target.value)}
              className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
              {['bronze', 'silver', 'gold', 'platinum', 'diamond'].map(v => (
                <option key={v} value={v}>{t(tierKey(v))}</option>
              ))}
            </select>
          </div>
          <textarea value={description} onChange={e => setDescription(e.target.value)} placeholder={t('agency.description')}
            className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600 resize-none h-16" />
          <div className="flex gap-2">
            <button onClick={handleSubmit}
              className="text-xs bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-1.5 rounded-lg font-semibold transition-colors">
              {editId ? t('agency.updateAgency') : t('agency.createAgency')}
            </button>
            {editId && (
              <button onClick={() => { resetForm(); setShowForm(false); }}
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
          { key: 'owner_name', label: t('agency.col.owner'), sortable: true },
          { key: 'tier', label: t('agency.col.tier'), sortable: true, render: a => {
            const h = a as HostAgencyModel;
            const tierT = t(tierKey(h.tier ?? 'bronze'));
            return <span className={tierColors[h.tier ?? 'bronze'] + ' font-semibold'}>{tierT}</span>;
          }},
          { key: 'specialty', label: t('agency.col.specialty'), sortable: true, render: a => {
            const s = (a as HostAgencyModel).specialty;
            return <span className="text-slate-400">{t(`agency.specialty.${s}` as any)}</span>;
          }},
          { key: 'commission_rate', label: t('agency.col.commission'), sortable: true, render: a => <span>{(a as HostAgencyModel).commission_rate * 100}%</span> },
          { key: 'member_count', label: t('agency.col.members'), sortable: true },
          { key: 'total_diamonds_earned', label: t('agency.col.totalDiamonds'), sortable: true, render: a => <span className="text-cyan-400">{(a as HostAgencyModel).total_diamonds_earned?.toLocaleString() ?? '0'}</span> },
          { key: 'monthly_diamonds', label: t('agency.col.monthlyDiamonds'), sortable: true, render: a => <span className="text-amber-400">{(a as HostAgencyModel).monthly_diamonds?.toLocaleString() ?? '0'}</span> },
          { key: 'country', label: t('agency.col.country'), sortable: true, render: a => <span className="text-slate-500 uppercase">{(a as HostAgencyModel).country || '—'}</span> },
          { key: 'is_active', label: t('agency.col.active'), sortable: true, render: a => {
            const active = (a as HostAgencyModel).is_active;
            return <span className={active ? 'text-emerald-400' : 'text-rose-400'}>{active ? t('agency.yes') : t('agency.no')}</span>;
          }},
        ]}
        data={agencies}
        searchKeys={['name', 'owner_name', 'specialty', 'country', 'tier']}
        onEdit={a => openEdit(a as HostAgencyModel)}
        onDelete={async a => {
          if (confirm(t('agency.deleteConfirm'))) { await deleteHostAgency((a as HostAgencyModel).id); load(); }
        }}
      />
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
      title: title.trim(), target_diamonds: parseInt(targetDiamonds),
      reward_type: rewardType as HostMilestoneModel['reward_type'],
      reward_value: parseInt(rewardValue), reward_item_id: rewardItemId.trim() || null,
      period_type: periodType as HostMilestoneModel['period_type'],
      is_active: true, sort_order: parseInt(sortOrder),
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
