import { useEffect, useMemo, useState } from 'react';
import { deleteRoom, listRooms, updateRoom } from '../lib/api';
import { supabase } from '../lib/supabase';
import type { RoomRow } from '../lib/types';
import { Badge, Field, FullSpinner, Modal, PageHeader, SearchBox, Toggle, useToast, fmtDate, fmtNumber } from '../lib/ui';

export default function Rooms() {
  const [rows, setRows] = useState<RoomRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState('');
  const [edit, setEdit] = useState<RoomRow | null>(null);
  const [saving, setSaving] = useState(false);
  const toast = useToast();

  const load = () => {
    listRooms()
      .then(setRows)
      .catch((e) => toast.push(e.message, 'err'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
    const sub = supabase
      .channel('dashboard-rooms')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'rooms' }, () => load())
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
      (r) =>
        (r.room_name || '').toLowerCase().includes(q) ||
        (r.room_id || '').toLowerCase().includes(q) ||
        (r.owner_name || '').toLowerCase().includes(q) ||
        (r.category || '').toLowerCase().includes(q),
    );
  }, [rows, query]);

  const save = async () => {
    if (!edit) return;
    setSaving(true);
    try {
      await updateRoom(edit.room_id, {
        room_name: edit.room_name,
        description: edit.description,
        category: edit.category,
        status: edit.status,
        is_active: edit.is_active,
        participant_count: Number(edit.participant_count),
        active_mic_count: Number(edit.active_mic_count),
        is_chat_enabled: edit.is_chat_enabled,
      });
      toast.push('تم تحديث الغرفة');
      setEdit(null);
      load();
    } catch (e: any) {
      toast.push(e.message, 'err');
    } finally {
      setSaving(false);
    }
  };

  const toggleActive = async (r: RoomRow, v: boolean) => {
    try {
      await updateRoom(r.room_id, { is_active: v, status: v ? 'active' : 'closed' });
      setRows((prev) => prev.map((x) => (x.room_id === r.room_id ? { ...x, is_active: v, status: v ? 'active' : 'closed' } : x)));
    } catch (e: any) {
      toast.push(e.message, 'err');
    }
  };

  const remove = async (r: RoomRow) => {
    if (!confirm(`حذف الغرفة ${r.room_name} مع كل رسائلها؟`)) return;
    try {
      await deleteRoom(r.room_id);
      toast.push('تم حذف الغرفة');
      load();
    } catch (e: any) {
      toast.push(e.message, 'err');
    }
  };

  if (loading) return <FullSpinner />;

  return (
    <div>
      <PageHeader title="الغرف" subtitle="إدارة الغرف الصوتية على جدول rooms" />
      <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
        <SearchBox value={query} onChange={setQuery} placeholder="بحث بالاسم / الكود / المالك..." />
        <span className="badge badge-blue">{filtered.length} غرفة</span>
      </div>

      <div className="table-wrap">
        <table className="rt">
          <thead>
            <tr>
              <th>الغرفة</th>
              <th>الكود</th>
              <th>التصنيف</th>
              <th>المايكات</th>
              <th>الحضور</th>
              <th>الحالة</th>
              <th>مفعلة</th>
              <th>آخر نشاط</th>
              <th>إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((r) => (
              <tr key={r.room_id}>
                <td>
                  <div style={{ fontWeight: 700 }}>{r.room_name || 'بلا اسم'}</div>
                  <div style={{ color: 'var(--muted)', fontSize: 11 }}>{r.owner_name || ''}</div>
                </td>
                <td style={{ direction: 'ltr' }}>{r.room_id}</td>
                <td>{r.category || '—'}</td>
                <td>{r.active_mic_count}</td>
                <td>
                  <Badge kind="blue">{fmtNumber(r.participant_count)} مستخدم</Badge>
                </td>
                <td>
                  <Badge kind={r.is_active ? 'green' : 'red'}>{r.status}</Badge>
                </td>
                <td>
                  <Toggle checked={r.is_active} onChange={(v) => toggleActive(r, v)} />
                </td>
                <td style={{ color: 'var(--muted)', fontSize: 12 }}>{fmtDate(r.last_active)}</td>
                <td>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button className="btn btn-ghost" style={{ padding: '5px 10px', fontSize: 12 }} onClick={() => setEdit(r)}>
                      تعديل
                    </button>
                    <button className="btn btn-danger" style={{ padding: '5px 10px', fontSize: 12 }} onClick={() => remove(r)}>
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
        <Modal title={`تعديل الغرفة: ${edit.room_name}`} onClose={() => setEdit(null)} wide>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 14px' }}>
            <Field label="اسم الغرفة">
              <input className="input" value={edit.room_name || ''} onChange={(e) => setEdit({ ...edit, room_name: e.target.value })} />
            </Field>
            <Field label="الكود">
              <input className="input" disabled value={edit.room_id} />
            </Field>
            <Field label="التصنيف">
              <input className="input" value={edit.category || ''} onChange={(e) => setEdit({ ...edit, category: e.target.value })} />
            </Field>
            <Field label="عدد المايكات">
              <input className="input" type="number" value={edit.active_mic_count ?? 0} onChange={(e) => setEdit({ ...edit, active_mic_count: Number(e.target.value) })} />
            </Field>
            <Field label="عدد الحضور">
              <input className="input" type="number" value={edit.participant_count ?? 0} onChange={(e) => setEdit({ ...edit, participant_count: Number(e.target.value) })} />
            </Field>
            <Field label="الحالة">
              <select className="select" value={edit.status} onChange={(e) => setEdit({ ...edit, status: e.target.value })}>
                <option>active</option>
                <option>closed</option>
                <option>pending</option>
              </select>
            </Field>
            <Field label="الوصف">
              <textarea className="textarea" rows={3} value={edit.description || ''} onChange={(e) => setEdit({ ...edit, description: e.target.value })} />
            </Field>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, paddingTop: 8 }}>
              <Toggle checked={edit.is_active} onChange={(v) => setEdit({ ...edit, is_active: v })} />
              <span style={{ color: 'var(--muted)' }}>غرفة مفعلة</span>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
            <button className="btn btn-gold" onClick={save} disabled={saving}>
              {saving ? '...' : 'حفظ'}
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
