import { useEffect, useState, useContext } from 'react';
import { I18nContext } from '../lib/i18n';
import { getAdminSupabase } from '../lib/supabase';
import type { AppUser } from '../lib/auth';
import { NAV_GROUPS } from '../lib/nav';
import {
  Shield, ShieldOff, UserPlus, Trash2, Ban, CheckCircle, XCircle,
  Search, Save, X, RefreshCw, LogIn,
  Camera, AlertTriangle, FileText,
} from 'lucide-react';
import {
  getAdminUsers, createAdminUser, updateAdminUser, deleteAdminUser,
  getAdminActionLogs, clearActionLogs, logAdminAction,
  getDashboardBans, banFromDashboard, unbanFromDashboard,
} from '../lib/db';
import type { AdminUser, AdminActionLog, DashboardBan } from '../types';

// Every page is its own permission toggle, grouped exactly like the sidebar.
const ALL_PERMISSIONS: { key: string; ar: string; en: string }[] = NAV_GROUPS.flatMap(
  (g) => g.items.map((it) => ({ key: it.key, ar: it.label, en: it.label })),
);

export default function AdminManagement({ currentUser }: { currentUser: AppUser | null }) {
  const { t, lang } = useContext(I18nContext);
  const isAr = lang === 'ar';
  const [tab, setTab] = useState<'admins' | 'logs' | 'bans' | 'profile'>('admins');
  const [admins, setAdmins] = useState<AdminUser[]>([]);
  const [logs, setLogs] = useState<AdminActionLog[]>([]);
  const [bans, setBans] = useState<DashboardBan[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQ, setSearchQ] = useState('');

  const [showAddModal, setShowAddModal] = useState(false);
  const [addForm, setAddForm] = useState({ uid: '', email: '', password: '', displayName: '', role: 'moderator' as AdminUser['role'], permissions: {} as Record<string, boolean> });
  const [addError, setAddError] = useState('');
  const [addSaving, setAddSaving] = useState(false);

  const [editingAdmin, setEditingAdmin] = useState<AdminUser | null>(null);
  const [editForm, setEditForm] = useState({ displayName: '', role: '' as string, permissions: {} as Record<string, boolean> });

  const [confirmDelete, setConfirmDelete] = useState<string | null>(null);

  const [logFilter, setLogFilter] = useState('');

  const [banForm, setBanForm] = useState({ uid: '', email: '', reason: '' });
  const [banError, setBanError] = useState('');

  const [profileForm, setProfileForm] = useState({ displayName: '', photoUrl: '' });
  const [profilePass, setProfilePass] = useState('');
  const [profileSaving, setProfileSaving] = useState(false);
  const [profileMsg, setProfileMsg] = useState('');

  const load = async () => {
    setLoading(true);
    const [a, l, b] = await Promise.all([getAdminUsers(), getAdminActionLogs(), getDashboardBans()]);
    setAdmins(a);
    setLogs(l);
    setBans(b);
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const resetAddForm = () => {
    setAddForm({ uid: '', email: '', password: '', displayName: '', role: 'moderator', permissions: {} });
    setAddError('');
  };

  const handleCreate = async () => {
    setAddError('');
    if (!addForm.email || !addForm.password) { setAddError(isAr ? 'البريد الإلكتروني وكلمة المرور مطلوبان' : 'Email and password required'); return; }
    if (!addForm.password || addForm.password.length < 6) { setAddError(isAr ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : 'Password must be at least 6 characters'); return; }
    setAddSaving(true);
    try {
      const uid = addForm.uid || `admin_${Date.now()}`;
      const perms: Record<string, boolean> = {};
      for (const p of ALL_PERMISSIONS) perms[p.key] = addForm.permissions[p.key] || false;
      await createAdminUser(uid, {
        email: addForm.email,
        displayName: addForm.displayName,
        role: addForm.role,
        permissions: perms,
        createdBy: currentUser?.id || '',
      }, addForm.password);
      await logAdminAction(currentUser?.id || '', addForm.displayName || currentUser?.email || '', 'create_admin', 'admin', uid, { email: addForm.email, role: addForm.role });
      setShowAddModal(false);
      resetAddForm();
      load();
    } catch (e: any) { setAddError(e?.message || 'Error creating admin'); }
    setAddSaving(false);
  };

  const startEdit = (admin: AdminUser) => {
    setEditingAdmin(admin);
    setEditForm({ displayName: admin.displayName, role: admin.role, permissions: { ...admin.permissions } });
  };

  const handleEditSave = async () => {
    if (!editingAdmin) return;
    try {
      await updateAdminUser(editingAdmin.uid, { displayName: editForm.displayName, role: editForm.role as AdminUser['role'], permissions: editForm.permissions });
      await logAdminAction(currentUser?.id || '', currentUser?.email || '', 'update_admin', 'admin', editingAdmin.uid, { role: editForm.role });
      setEditingAdmin(null);
      load();
    } catch (e: any) { alert(e?.message || 'Error updating admin'); }
  };

  const toggleActive = async (admin: AdminUser) => {
    try {
      await updateAdminUser(admin.uid, { isActive: !admin.isActive });
      await logAdminAction(currentUser?.id || '', currentUser?.email || '', admin.isActive ? 'disable_admin' : 'enable_admin', 'admin', admin.uid);
      load();
    } catch (e: any) { alert(e?.message || 'Error toggling admin'); }
  };

  const handleDelete = async (uid: string) => {
    try {
      await deleteAdminUser(uid);
      await logAdminAction(currentUser?.id || '', currentUser?.email || '', 'delete_admin', 'admin', uid);
      setConfirmDelete(null);
      load();
    } catch (e: any) { alert(e?.message || 'Error deleting admin'); }
  };

  const handleBan = async () => {
    setBanError('');
    if (!banForm.uid || !banForm.reason) { setBanError(isAr ? 'المعرف والسبب مطلوبان' : 'UID and reason required'); return; }
    try {
      await banFromDashboard(banForm.uid, banForm.email, banForm.reason, currentUser?.id || '');
      await logAdminAction(currentUser?.id || '', currentUser?.email || '', 'ban_dashboard', 'user', banForm.uid, { reason: banForm.reason });
      setBanForm({ uid: '', email: '', reason: '' });
      load();
    } catch (e: any) { setBanError(e?.message || 'Error banning user'); }
  };

  const handleUnban = async (uid: string) => {
    try {
      await unbanFromDashboard(uid);
      await logAdminAction(currentUser?.id || '', currentUser?.email || '', 'unban_dashboard', 'user', uid);
      load();
    } catch { }
  };

  const handleProfileSave = async () => {
    if (!currentUser) return;
    setProfileSaving(true);
    setProfileMsg('');
    try {
      await updateAdminUser(currentUser.id, { displayName: profileForm.displayName, photoUrl: profileForm.photoUrl });
      if (profilePass) {
        const adminClient = getAdminSupabase();
        if (adminClient) {
          await adminClient.auth.admin.updateUserById(currentUser.id, { password: profilePass });
        }
      }
      setProfileMsg(isAr ? 'تم الحفظ' : 'Saved');
      setProfilePass('');
      load();
    } catch (e: any) { setProfileMsg(e?.message || 'Error saving profile'); }
    setProfileSaving(false);
  };

  const handleClearLogs = async () => {
    if (!confirm(isAr ? 'مسح جميع السجلات؟' : 'Clear all logs?')) return;
    await clearActionLogs();
    load();
  };

  const getAdminProfile = (): AdminUser | undefined => admins.find(a => a.uid === currentUser?.id);

  const filteredAdmins = admins.filter(a =>
    !searchQ || a.email.toLowerCase().includes(searchQ.toLowerCase()) || a.displayName.toLowerCase().includes(searchQ.toLowerCase())
  );

  const filteredLogs = logs.filter(l =>
    !logFilter || l.adminName.toLowerCase().includes(logFilter.toLowerCase()) || l.action.toLowerCase().includes(logFilter.toLowerCase())
  );

  const tabs = [
    { key: 'admins' as const, ar: 'المشرفين', en: 'Admins', icon: Shield },
    { key: 'logs' as const, ar: 'سجل الإجراءات', en: 'Action Logs', icon: FileText },
    { key: 'bans' as const, ar: 'الحظر', en: 'Bans', icon: Ban },
    { key: 'profile' as const, ar: 'ملفي الشخصي', en: 'My Profile', icon: Camera },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">{isAr ? 'إدارة المشرفين' : 'Admin Management'}</h2>
          <p className="text-slate-500 text-xs mt-0.5">{admins.length} {isAr ? 'مشرف' : 'admins'}</p>
        </div>
        <button onClick={load} className="px-3 py-1.5 bg-[#141417] border border-white/5 hover:border-white/10 text-xs text-slate-300 font-semibold rounded-lg flex items-center gap-1">
          <RefreshCw className="w-3.5 h-3.5" /> {isAr ? 'تحديث' : 'Refresh'}
        </button>
      </div>

      {/* Tabs */}
      <div className={`flex gap-1 p-1 bg-[#141417] rounded-xl border border-white/5 w-fit ${isAr ? 'flex-row-reverse' : ''}`}>
        {tabs.map(t => {
          const Icon = t.icon;
          return (
            <button key={t.key} onClick={() => setTab(t.key)}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${tab === t.key ? 'bg-indigo-500/10 text-indigo-300' : 'text-slate-400 hover:text-white'}`}>
              <Icon className="w-3.5 h-3.5" />
              <span>{isAr ? t.ar : t.en}</span>
            </button>
          );
        })}
      </div>

      {loading ? (
        <div className="text-center py-20 text-slate-500 text-xs">{t('loading')}</div>
      ) : (
        <>
          {/* === ADMINS TAB === */}
          {tab === 'admins' && (
            <div className="space-y-4">
              <div className={`flex items-center gap-3 ${isAr ? 'flex-row-reverse' : ''}`}>
                <div className="relative flex-1 max-w-xs">
                  <Search className={`w-3.5 h-3.5 absolute top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none ${isAr ? 'right-3' : 'left-3'}`} />
                  <input type="text" value={searchQ} onChange={e => setSearchQ(e.target.value)}
                    placeholder={isAr ? 'بحث عن مشرف...' : 'Search admin...'}
                    className={`w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 ${isAr ? 'pr-9 pl-3' : 'pl-9 pr-3'} text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600`} />
                </div>
                <button onClick={() => { setShowAddModal(true); resetAddForm(); }} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
                  <UserPlus className="w-3.5 h-3.5" /> {isAr ? 'إضافة مشرف' : 'Add Admin'}
                </button>
              </div>

              <div className="bg-[#141417] rounded-2xl border border-white/5 overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="border-b border-white/5 text-slate-500">
                        <th className="text-right p-3 font-medium">{isAr ? 'المشرف' : 'Admin'}</th>
                        <th className="text-right p-3 font-medium">{isAr ? 'البريد' : 'Email'}</th>
                        <th className="text-right p-3 font-medium">{isAr ? 'الدور' : 'Role'}</th>
                        <th className="text-right p-3 font-medium">{isAr ? 'الحالة' : 'Status'}</th>
                        <th className="text-right p-3 font-medium">{isAr ? 'الإجراءات' : 'Actions'}</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredAdmins.map(admin => (
                        <tr key={admin.uid} className="border-b border-white/5 hover:bg-white/[0.02]">
                          <td className="p-3">
                            <div className={`flex items-center gap-2.5 ${isAr ? 'flex-row-reverse' : ''}`}>
                              {admin.photoUrl ? (
                                <img src={admin.photoUrl} alt="" className="w-7 h-7 rounded-full object-cover" />
                              ) : (
                                <div className="w-7 h-7 rounded-full bg-gradient-to-br from-indigo-600 to-rose-500 flex items-center justify-center text-[10px] font-bold text-white">
                                  {(admin.displayName || admin.email)[0]?.toUpperCase() || 'A'}
                                </div>
                              )}
                              <span className="text-white font-medium">{admin.displayName || admin.email}</span>
                            </div>
                          </td>
                          <td className="p-3 text-slate-400">{admin.email}</td>
                          <td className="p-3">
                            <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${
                              admin.role === 'superadmin' ? 'bg-rose-500/10 text-rose-300' :
                              admin.role === 'admin' ? 'bg-indigo-500/10 text-indigo-300' :
                              'bg-slate-500/10 text-slate-300'
                            }`}>
                              {admin.role}
                            </span>
                          </td>
                          <td className="p-3">
                            {admin.isActive ? (
                              <span className="flex items-center gap-1 text-emerald-400"><CheckCircle className="w-3 h-3" /> {isAr ? 'نشط' : 'Active'}</span>
                            ) : (
                              <span className="flex items-center gap-1 text-rose-400"><XCircle className="w-3 h-3" /> {isAr ? 'معطل' : 'Disabled'}</span>
                            )}
                          </td>
                          <td className="p-3">
                            <div className={`flex items-center gap-1.5 ${isAr ? 'flex-row-reverse' : ''}`}>
                              <button onClick={() => startEdit(admin)} className="p-1.5 rounded-lg bg-indigo-500/10 text-indigo-300 hover:bg-indigo-500/20">
                                <Shield className="w-3.5 h-3.5" />
                              </button>
                              <button onClick={() => toggleActive(admin)} className="p-1.5 rounded-lg bg-slate-500/10 text-slate-400 hover:bg-slate-500/20">
                                {admin.isActive ? <ShieldOff className="w-3.5 h-3.5" /> : <Shield className="w-3.5 h-3.5" />}
                              </button>
                              {admin.role !== 'superadmin' && (
                                <button onClick={() => setConfirmDelete(admin.uid)} className="p-1.5 rounded-lg bg-rose-500/10 text-rose-300 hover:bg-rose-500/20">
                                  <Trash2 className="w-3.5 h-3.5" />
                                </button>
                              )}
                            </div>
                          </td>
                        </tr>
                      ))}
                      {filteredAdmins.length === 0 && (
                        <tr><td colSpan={5} className="p-8 text-center text-slate-500">{isAr ? 'لا يوجد مشرفين' : 'No admins found'}</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* === LOGS TAB === */}
          {tab === 'logs' && (
            <div className="space-y-4">
              <div className={`flex items-center gap-3 ${isAr ? 'flex-row-reverse' : ''}`}>
                <div className="relative flex-1 max-w-xs">
                  <Search className={`w-3.5 h-3.5 absolute top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none ${isAr ? 'right-3' : 'left-3'}`} />
                  <input type="text" value={logFilter} onChange={e => setLogFilter(e.target.value)}
                    placeholder={isAr ? 'بحث في السجلات...' : 'Search logs...'}
                    className={`w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 ${isAr ? 'pr-9 pl-3' : 'pl-9 pr-3'} text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600`} />
                </div>
                <button onClick={handleClearLogs} className="px-3 py-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-300 text-xs font-semibold rounded-lg flex items-center gap-1">
                  <Trash2 className="w-3.5 h-3.5" /> {isAr ? 'مسح الكل' : 'Clear All'}
                </button>
              </div>

              <div className="bg-[#141417] rounded-2xl border border-white/5 overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="border-b border-white/5 text-slate-500">
                        <th className="text-right p-3 font-medium">{isAr ? 'التاريخ' : 'Date'}</th>
                        <th className="text-right p-3 font-medium">{isAr ? 'المشرف' : 'Admin'}</th>
                        <th className="text-right p-3 font-medium">{isAr ? 'الإجراء' : 'Action'}</th>
                        <th className="text-right p-3 font-medium">{isAr ? 'النوع' : 'Target'}</th>
                        <th className="text-right p-3 font-medium">{isAr ? 'التفاصيل' : 'Details'}</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredLogs.slice(0, 200).map(log => (
                        <tr key={log.id} className="border-b border-white/5 hover:bg-white/[0.02]">
                          <td className="p-3 text-slate-400 whitespace-nowrap">
                            {new Date(log.createdAt).toLocaleString(isAr ? 'ar-SA' : 'en-US', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
                          </td>
                          <td className="p-3 text-white">{log.adminName}</td>
                          <td className="p-3">
                            <span className="px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-300 text-[10px] font-mono">{log.action}</span>
                          </td>
                          <td className="p-3 text-slate-400">{log.targetType}/{log.targetId?.slice(0, 12)}</td>
                          <td className="p-3 text-slate-500 max-w-[200px] truncate">
                            {JSON.stringify(log.details).slice(0, 60)}
                          </td>
                        </tr>
                      ))}
                      {filteredLogs.length === 0 && (
                        <tr><td colSpan={5} className="p-8 text-center text-slate-500">{isAr ? 'لا توجد سجلات' : 'No logs found'}</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
                {filteredLogs.length > 200 && (
                  <div className="p-3 text-center text-slate-500 text-[10px] border-t border-white/5">
                    {isAr ? 'عرض آخر 200 سجل' : 'Showing last 200 entries'}
                  </div>
                )}
              </div>
            </div>
          )}

          {/* === BANS TAB === */}
          {tab === 'bans' && (
            <div className="space-y-4">
              <div className="bg-[#141417] rounded-2xl border border-white/5 p-5 space-y-4">
                <h3 className="text-white font-semibold text-sm flex items-center gap-2">
                  <Ban className="w-4 h-4 text-rose-400" />
                  {isAr ? 'حظر مستخدم من لوحة التحكم' : 'Ban User from Dashboard'}
                </h3>
                <div className={`grid grid-cols-1 md:grid-cols-3 gap-3 ${isAr ? 'md:text-right' : ''}`}>
                  <div>
                    <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'معرف المستخدم' : 'User UID'}</label>
                    <input type="text" value={banForm.uid} onChange={e => setBanForm(p => ({ ...p, uid: e.target.value }))}
                      className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
                  </div>
                  <div>
                    <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'البريد (اختياري)' : 'Email (optional)'}</label>
                    <input type="text" value={banForm.email} onChange={e => setBanForm(p => ({ ...p, email: e.target.value }))}
                      className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
                  </div>
                  <div>
                    <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'السبب' : 'Reason'}</label>
                    <input type="text" value={banForm.reason} onChange={e => setBanForm(p => ({ ...p, reason: e.target.value }))}
                      className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600" />
                  </div>
                </div>
                {banError && <p className="text-rose-400 text-[10px]">{banError}</p>}
                <button onClick={handleBan} className="px-4 py-1.5 bg-rose-600 hover:bg-rose-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
                  <Ban className="w-3.5 h-3.5" /> {isAr ? 'حظر' : 'Ban'}
                </button>
              </div>

              <div className="bg-[#141417] rounded-2xl border border-white/5 overflow-hidden">
                <div className="p-3 border-b border-white/5">
                  <span className="text-xs text-slate-400">{isAr ? 'المستخدمون المحظورون' : 'Banned Users'} ({bans.length})</span>
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="border-b border-white/5 text-slate-500">
                        <th className="text-right p-3 font-medium">{isAr ? 'المستخدم' : 'User'}</th>
                        <th className="text-right p-3 font-medium">{isAr ? 'السبب' : 'Reason'}</th>
                        <th className="text-right p-3 font-medium">{isAr ? 'تاريخ الحظر' : 'Banned At'}</th>
                        <th className="text-right p-3 font-medium">{isAr ? 'الإجراءات' : 'Actions'}</th>
                      </tr>
                    </thead>
                    <tbody>
                      {bans.map(ban => (
                        <tr key={ban.uid} className="border-b border-white/5 hover:bg-white/[0.02]">
                          <td className="p-3">
                            <div className="text-white font-medium">{ban.uid.slice(0, 16)}...</div>
                            {ban.email && <div className="text-slate-500 text-[10px]">{ban.email}</div>}
                          </td>
                          <td className="p-3 text-slate-400">{ban.reason}</td>
                          <td className="p-3 text-slate-400">{new Date(ban.bannedAt).toLocaleDateString()}</td>
                          <td className="p-3">
                            <button onClick={() => handleUnban(ban.uid)} className="p-1.5 rounded-lg bg-emerald-500/10 text-emerald-300 hover:bg-emerald-500/20">
                              <LogIn className="w-3.5 h-3.5" />
                            </button>
                          </td>
                        </tr>
                      ))}
                      {bans.length === 0 && (
                        <tr><td colSpan={4} className="p-8 text-center text-slate-500">{isAr ? 'لا يوجد محظورين' : 'No banned users'}</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* === PROFILE TAB === */}
          {tab === 'profile' && (
            <div className="max-w-lg mx-auto space-y-6">
              <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-5">
                <div className={`flex items-center gap-4 ${isAr ? 'flex-row-reverse' : ''}`}>
                  <div className="w-16 h-16 rounded-full bg-gradient-to-br from-indigo-600 to-rose-500 flex items-center justify-center text-xl font-bold text-white shrink-0 overflow-hidden">
                    {profileForm.photoUrl ? (
                      <img src={profileForm.photoUrl} alt="" className="w-full h-full object-cover" />
                    ) : (
                      (currentUser?.email?.[0]?.toUpperCase() || 'A')
                    )}
                  </div>
                  <div>
                    <h3 className="text-white font-semibold">{profileForm.displayName || currentUser?.email}</h3>
                    <p className="text-slate-500 text-[11px]">{currentUser?.email}</p>
                  </div>
                </div>

                <div>
                  <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'الاسم المعروض' : 'Display Name'}</label>
                  <input type="text" value={profileForm.displayName} onChange={e => setProfileForm(p => ({ ...p, displayName: e.target.value }))}
                    className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600"
                    placeholder={currentUser?.email || ''} />
                </div>

                <div>
                  <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'رابط الصورة' : 'Photo URL'}</label>
                  <input type="text" value={profileForm.photoUrl} onChange={e => setProfileForm(p => ({ ...p, photoUrl: e.target.value }))}
                    className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600"
                    placeholder="https://..." />
                </div>

                <div>
                  <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'كلمة المرور الجديدة' : 'New Password'} {isAr ? '(اتركها فارغة لعدم التغيير)' : '(leave empty to keep)'}</label>
                  <input type="password" value={profilePass} onChange={e => setProfilePass(e.target.value)}
                    className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600"
                    placeholder="••••••" />
                </div>

                {profileMsg && <p className={`text-xs ${profileMsg === 'Saved' || profileMsg === 'تم الحفظ' ? 'text-emerald-400' : 'text-rose-400'}`}>{profileMsg}</p>}

                <button onClick={handleProfileSave} disabled={profileSaving}
                  className="px-4 py-1.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
                  <Save className="w-3.5 h-3.5" /> {profileSaving ? t('saving') : t('save')}
                </button>
              </div>
            </div>
          )}
        </>
      )}

      {/* === ADD ADMIN MODAL === */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4" onClick={() => setShowAddModal(false)}>
          <div className="bg-[#141417] border border-white/10 rounded-2xl p-6 w-full max-w-lg max-h-[90vh] overflow-y-auto space-y-4 shadow-2xl" onClick={e => e.stopPropagation()}>
            <div className={`flex items-center justify-between ${isAr ? 'flex-row-reverse' : ''}`}>
              <h3 className="text-white font-semibold text-sm flex items-center gap-2">
                <UserPlus className="w-4 h-4 text-indigo-400" />
                {isAr ? 'إضافة مشرف جديد' : 'Add New Admin'}
              </h3>
              <button onClick={() => setShowAddModal(false)} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
            </div>

            <div className="space-y-3">
              <div>
                <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'البريد الإلكتروني' : 'Email'}</label>
                <input type="email" value={addForm.email} onChange={e => setAddForm(p => ({ ...p, email: e.target.value }))}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500" />
              </div>
              <div>
                <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'كلمة المرور' : 'Password'}</label>
                <input type="password" value={addForm.password} onChange={e => setAddForm(p => ({ ...p, password: e.target.value }))}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500" />
              </div>
              <div>
                <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'الاسم' : 'Display Name'}</label>
                <input type="text" value={addForm.displayName} onChange={e => setAddForm(p => ({ ...p, displayName: e.target.value }))}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500" />
              </div>
              <div>
                <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'الدور' : 'Role'}</label>
                <select value={addForm.role} onChange={e => setAddForm(p => ({ ...p, role: e.target.value as AdminUser['role'] }))}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
                  <option value="moderator">{isAr ? 'مشرف' : 'Moderator'}</option>
                  <option value="admin">Admin</option>
                  <option value="superadmin">Super Admin</option>
                </select>
              </div>
              <div>
                <label className="block text-[10px] text-slate-500 mb-2">{isAr ? 'الصلاحيات' : 'Permissions'}</label>
                <div className="grid grid-cols-2 gap-1.5">
                  {ALL_PERMISSIONS.map(p => (
                    <label key={p.key} className={`flex items-center gap-2 px-2 py-1.5 rounded-lg cursor-pointer text-[11px] ${addForm.permissions[p.key] ? 'bg-indigo-500/10 text-indigo-300' : 'bg-white/5 text-slate-400'} ${isAr ? 'flex-row-reverse' : ''}`}>
                      <input type="checkbox" checked={!!addForm.permissions[p.key]}
                        onChange={e => setAddForm(prev => ({ ...prev, permissions: { ...prev.permissions, [p.key]: e.target.checked } }))}
                        className="accent-indigo-500" />
                      {isAr ? p.ar : p.en}
                    </label>
                  ))}
                </div>
              </div>
            </div>

            {addError && <p className="text-rose-400 text-[10px]">{addError}</p>}

            <button onClick={handleCreate} disabled={addSaving}
              className="w-full py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-xs text-white font-semibold rounded-lg flex items-center justify-center gap-1">
              {addSaving ? t('saving') : (isAr ? 'إضافة المشرف' : 'Add Admin')}
            </button>
          </div>
        </div>
      )}

      {/* === EDIT PERMISSIONS MODAL === */}
      {editingAdmin && (
        <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4" onClick={() => setEditingAdmin(null)}>
          <div className="bg-[#141417] border border-white/10 rounded-2xl p-6 w-full max-w-lg max-h-[90vh] overflow-y-auto space-y-4 shadow-2xl" onClick={e => e.stopPropagation()}>
            <div className={`flex items-center justify-between ${isAr ? 'flex-row-reverse' : ''}`}>
              <h3 className="text-white font-semibold text-sm flex items-center gap-2">
                <Shield className="w-4 h-4 text-indigo-400" />
                {isAr ? 'تعديل المشرف' : 'Edit Admin'} — {editingAdmin.displayName || editingAdmin.email}
              </h3>
              <button onClick={() => setEditingAdmin(null)} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
            </div>

            <div className="space-y-3">
              <div>
                <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'الاسم' : 'Display Name'}</label>
                <input type="text" value={editForm.displayName} onChange={e => setEditForm(p => ({ ...p, displayName: e.target.value }))}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500" />
              </div>
              <div>
                <label className="block text-[10px] text-slate-500 mb-1">{isAr ? 'الدور' : 'Role'}</label>
                <select value={editForm.role} onChange={e => setEditForm(p => ({ ...p, role: e.target.value }))}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
                  <option value="moderator">{isAr ? 'مشرف' : 'Moderator'}</option>
                  <option value="admin">Admin</option>
                  <option value="superadmin">Super Admin</option>
                </select>
              </div>
              <div>
                <label className="block text-[10px] text-slate-500 mb-2">{isAr ? 'الصلاحيات' : 'Permissions'}</label>
                <div className="grid grid-cols-2 gap-1.5">
                  {ALL_PERMISSIONS.map(p => (
                    <label key={p.key} className={`flex items-center gap-2 px-2 py-1.5 rounded-lg cursor-pointer text-[11px] ${editForm.permissions[p.key] ? 'bg-indigo-500/10 text-indigo-300' : 'bg-white/5 text-slate-400'} ${isAr ? 'flex-row-reverse' : ''}`}>
                      <input type="checkbox" checked={!!editForm.permissions[p.key]}
                        onChange={e => setEditForm(prev => ({ ...prev, permissions: { ...prev.permissions, [p.key]: e.target.checked } }))}
                        className="accent-indigo-500" />
                      {isAr ? p.ar : p.en}
                    </label>
                  ))}
                </div>
              </div>
            </div>

            <button onClick={handleEditSave} className="w-full py-2 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center justify-center gap-1">
              <Save className="w-3.5 h-3.5" /> {t('save')}
            </button>
          </div>
        </div>
      )}

      {/* === DELETE CONFIRMATION === */}
      {confirmDelete && (
        <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4" onClick={() => setConfirmDelete(null)}>
          <div className="bg-[#141417] border border-white/10 rounded-2xl p-6 w-full max-w-sm space-y-4 shadow-2xl" onClick={e => e.stopPropagation()}>
            <div className="flex items-center gap-2 text-rose-400">
              <AlertTriangle className="w-5 h-5" />
              <h3 className="text-white font-semibold text-sm">{isAr ? 'تأكيد الحذف' : 'Confirm Delete'}</h3>
            </div>
            <p className="text-slate-400 text-xs">{isAr ? 'هل أنت متأكد من حذف هذا المشرف؟ لا يمكن التراجع عن هذا الإجراء.' : 'Are you sure you want to delete this admin? This cannot be undone.'}</p>
            <div className={`flex gap-2 ${isAr ? 'flex-row-reverse' : ''}`}>
              <button onClick={() => setConfirmDelete(null)} className="flex-1 py-2 bg-white/5 hover:bg-white/10 text-xs text-slate-300 font-semibold rounded-lg">{t('cancel')}</button>
              <button onClick={() => handleDelete(confirmDelete)} className="flex-1 py-2 bg-rose-600 hover:bg-rose-700 text-xs text-white font-semibold rounded-lg">{t('delete')}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
