import { useEffect, useMemo, useState } from 'react';
import { deleteUser, listUsers, updateUser } from '../lib/api';
import { supabase } from '../lib/supabase';
import type { UserRow } from '../lib/types';
import {
  Badge,
  Field,
  FullSpinner,
  Modal,
  PageHeader,
  SearchBox,
  Toggle,
  useToast,
  fmtDate,
  fmtNumber,
} from '../lib/ui';

export default function Users() {
  const [rows, setRows] = useState<UserRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState('');
  const [edit, setEdit] = useState<UserRow | null>(null);
  const [saving, setSaving] = useState(false);
  const toast = useToast();

  const load = () => {
    listUsers()
      .then(setRows)
      .catch((e) => toast.push(e.message, 'err'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    const sub = supabase
      .channel('dashboard-users')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'users' }, () => load())
      .subscribe();
    return () => {
      supabase.removeChannel(sub);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return rows;
    return rows.filter(
      (u) =>
        (u.name || '').toLowerCase().includes(q) ||
        (u.numeric_id || '').toLowerCase().includes(q) ||
        (u.auth_uid || '').toLowerCase().includes(q) ||
        (u.email || '').toLowerCase().includes(q),
    );
  }, [rows, query]);

  const save = async () => {
    if (!edit) return;
    setSaving(true);
    try {
      const patch: Partial<UserRow> = {
        name: edit.name,
        gender: edit.gender,
        level: Number(edit.level),
        vip_level: Number(edit.vip_level),
        balance: Number(edit.balance),
        diamonds: Number(edit.diamonds),
        coins: Number(edit.coins),
        total_recharged: Number(edit.total_recharged),
        status: edit.status,
        role: edit.role,
        is_online: edit.is_online,
        is_agent: edit.is_agent,
        current_room_id: edit.current_room_id,
      };
      await updateUser(edit.auth_uid, patch);
      toast.push('تم تحديث المستخدم');
      setEdit(null);
      load();
    } catch (e: any) {
      toast.push(e.message, 'err');
    } finally {
      setSaving(false);
    }
  };

  const toggleOnline = async (u: UserRow, v: boolean) => {
    try {
      await updateUser(u.auth_uid, { is_online: v });
      setRows((prev) => prev.map((r) => (r.auth_uid === u.auth_uid ? { ...r, is_online: v } : r)));
    } catch (e: any) {
      toast.push(e.message, 'err');
    }
  };

  const remove = async (u: UserRow) => {
    if (!confirm(`حذف المستخدم ${u.name} نهائيًا؟`)) return;
    try {
      await deleteUser(u.auth_uid);
      toast.push('تم حذف المستخدم');
      load();
    } catch (e: any) {
      toast.push(e.message, 'err');
    }
  };

  if (loading) return <FullSpinner />;

  return (
    <div>
      <PageHeader title="المستخدمون" subtitle="قراءة وتعديل مباشر على جدول users" />
      <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
        <SearchBox value={query} onChange={setQuery} placeholder="بحث بالاسم / ID / البريد..." />
        <span className="badge badge-blue">{(filtered.length / rows.length || 0) === 1 ? rows.length : filtered.length} مستخدم</span>
      </div>

      <div className="table-wrap">
        <table className="rt">
          <thead>
            <tr>
              <th>المستخدم</th>
              <th>ID</th>
              <th>المستوى</th>
              <th>VIP</th>
              <th>الرصيد</th>
              <th>الماس</th>
              <th>الإجمالي</th>
              <th>الدور</th>
              <th>الحالة</th>
              <th>أونلاين</th>
              <th>التسجيل</th>
              <th>إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((u) => (
              <tr key={u.auth_uid}>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <img
                      src={u.photo_url || 'https://www.gravatar.com/avatar/?d=mp'}
                      alt=""
                      style={{ width: 32, height: 32, borderRadius: '50%', objectFit: 'cover', background: '#243350' }}
                      onError={(e) => ((e.target as HTMLImageElement).src = 'https://www.gravatar.com/avatar/?d=mp')}
                    />
                    <div>
                      <div style={{ fontWeight: 700 }}>{u.name || 'مستخدم'}</div>
                      <div style={{ color: 'var(--muted)', fontSize: 11 }}>{u.email || ''}</div>
                    </div>
                  </div>
                </td>
                <td>{u.numeric_id || '—'}</td>
                <td>{u.level}</td>
                <td>
                  <Badge kind={u.vip_level > 0 ? 'gold' : 'gray'}>VIP {u.vip_level}</Badge>
                </td>
                <td>{fmtNumber(u.balance || 0)}</td>
                <td>{fmtNumber(u.diamonds || 0)}</td>
                <td>{fmtNumber(u.total_recharged || 0)}</td>
                <td>
                  <Badge kind={u.role === 'owner' ? 'purple' : u.role === 'admin' ? 'gold' : 'gray'}>{u.role}</Badge>
                </td>
                <td>
                  <Badge kind={u.status === 'Active' ? 'green' : 'red'}>{u.status}</Badge>
                </td>
                <td>
                  <Toggle checked={u.is_online} onChange={(v) => toggleOnline(u, v)} />
                </td>
                <td style={{ color: 'var(--muted)', fontSize: 12 }}>{fmtDate(u.created_at)}</td>
                <td>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button className="btn btn-ghost" style={{ padding: '5px 10px', fontSize: 12 }} onClick={() => setEdit(u)}>
                      تعديل
                    </button>
                    <button className="btn btn-danger" style={{ padding: '5px 10px', fontSize: 12 }} onClick={() => remove(u)}>
                      حذف
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {edit && (
        <Modal title={`تعديل: ${edit.name || edit.auth_uid}`} onClose={() => setEdit(null)} wide>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 14px' }}>
            <Field label="الاسم">
              <input className="input" value={edit.name || ''} onChange={(e) => setEdit({ ...edit, name: e.target.value })} />
            </Field>
            <Field label="الجنس">
              <select className="select" value={edit.gender || 'Male'} onChange={(e) => setEdit({ ...edit, gender: e.target.value })}>
                <option>Male</option>
                <option>Female</option>
              </select>
            </Field>
            <Field label="المستوى">
              <input className="input" type="number" value={edit.level ?? 0} onChange={(e) => setEdit({ ...edit, level: Number(e.target.value) })} />
            </Field>
            <Field label="VIP">
              <input className="input" type="number" value={edit.vip_level ?? 0} onChange={(e) => setEdit({ ...edit, vip_level: Number(e.target.value) })} />
            </Field>
            <Field label="الرصيد (EGP)">
              <input className="input" type="number" value={edit.balance ?? 0} onChange={(e) => setEdit({ ...edit, balance: Number(e.target.value) })} />
            </Field>
            <Field label="الماس">
              <input className="input" type="number" value={edit.diamonds ?? 0} onChange={(e) => setEdit({ ...edit, diamonds: Number(e.target.value) })} />
            </Field>
            <Field label="العملات">
              <input className="input" type="number" value={edit.coins ?? 0} onChange={(e) => setEdit({ ...edit, coins: Number(e.target.value) })} />
            </Field>
            <Field label="إجمالي الشحن">
              <input className="input" type="number" value={edit.total_recharged ?? 0} onChange={(e) => setEdit({ ...edit, total_recharged: Number(e.target.value) })} />
            </Field>
            <Field label="الدور">
              <select className="select" value={edit.role} onChange={(e) => setEdit({ ...edit, role: e.target.value })}>
                <option value="user">user</option>
                <option value="admin">admin</option>
                <option value="owner">owner</option>
              </select>
            </Field>
            <Field label="الحالة">
              <select className="select" value={edit.status} onChange={(e) => setEdit({ ...edit, status: e.target.value })}>
                <option>Active</option>
                <option>Banned</option>
                <option>Suspended</option>
              </select>
            </Field>
            <Field label="الغرفة الحالية">
              <input className="input" value={edit.current_room_id || ''} onChange={(e) => setEdit({ ...edit, current_room_id: e.target.value })} />
            </Field>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, paddingTop: 8 }}>
              <Toggle checked={edit.is_online} onChange={(v) => setEdit({ ...edit, is_online: v })} />
              <span style={{ color: 'var(--muted)' }}>متصل الآن</span>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-start', marginTop: 18 }}>
            <button className="btn btn-gold" onClick={save} disabled={saving}>
              {saving ? '...' : 'حفظ التعديلات'}
            </button>
            <button className="btn btn-ghost" onClick={() => setEdit(null)}>
              إلغاء
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
