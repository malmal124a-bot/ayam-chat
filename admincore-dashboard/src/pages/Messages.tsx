import { useEffect, useMemo, useState } from 'react';
import { deleteMessage, listMessages } from '../lib/api';
import { supabase } from '../lib/supabase';
import type { MessageRow } from '../lib/types';
import { Badge, FullSpinner, PageHeader, SearchBox, useToast, fmtTime } from '../lib/ui';

export default function Messages() {
  const [rows, setRows] = useState<MessageRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [room, setRoom] = useState('');
  const [rooms, setRooms] = useState<string[]>([]);
  const toast = useToast();

  useEffect(() => {
    listMessages(300)
      .then((data) => {
        setRows(data);
        const uniq = Array.from(new Set(data.map((m) => m.room_id)));
        setRooms(uniq);
      })
      .catch((e) => toast.push(e.message, 'err'))
      .finally(() => setLoading(false));

    const sub = supabase
      .channel('dashboard-messages')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'messages' }, () => {
        listMessages(300)
          .then((data) => {
            setRows(data);
            setRooms((prev) => Array.from(new Set([...prev, ...data.map((m) => m.room_id)])));
          })
          .catch(() => {});
      })
      .subscribe();
    return () => {
      supabase.removeChannel(sub);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const filtered = useMemo(() => {
    const list = room ? rows.filter((m) => m.room_id === room) : rows;
    return list;
  }, [rows, room]);

  const remove = async (m: MessageRow) => {
    try {
      await deleteMessage(m.id);
      setRows((prev) => prev.filter((x) => x.id !== m.id));
      toast.push('تم حذف الرسالة');
    } catch (e: any) {
      toast.push(e.message, 'err');
    }
  };

  if (loading) return <FullSpinner />;

  return (
    <div>
      <PageHeader title="رسائل الغرف" subtitle="بث حي لجدول messages — قم بحذف أي رسالة مخالفة" />
      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <select className="select" style={{ maxWidth: 260 }} value={room} onChange={(e) => setRoom(e.target.value)}>
          <option value="">كل الغرف ({rows.length})</option>
          {rooms.map((r) => (
            <option key={r} value={r}>
              {r}
            </option>
          ))}
        </select>
        <SearchBox value="" onChange={() => {}} />
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {filtered.slice(0, 200).map((m) => {
          const isGift = m.type === 'gift';
          const isSystem = m.type === 'system';
          const isEntry = m.type === 'entryEffect';
          return (
            <div
              key={m.id}
              className="card fade-in"
              style={{
                padding: '12px 16px',
                display: 'flex',
                gap: 12,
                alignItems: 'center',
                borderColor: isGift ? 'rgba(245,185,66,0.4)' : undefined,
              }}
            >
              <span className={`badge ${isGift ? 'badge-gold' : isSystem ? 'badge-purple' : isEntry ? 'badge-blue' : 'badge-gray'}`}>
                {isGift ? '🎁' : isSystem ? '⚙️' : isEntry ? '✨' : '💬'}
              </span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, lineHeight: 1.7 }}>
                  <b>{m.sender_name || 'مجهول'}</b>
                  {m.target_name && <span style={{ color: 'var(--blue)' }}> ← {m.target_name}</span>}
                  {isGift && m.gift_name ? (
                    <span style={{ color: 'var(--gold)', fontWeight: 700 }}>
                      {' '}
                      أرسل {m.gift_name}
                      {m.gift_count && m.gift_count > 1 ? ` x${m.gift_count}` : ''}
                    </span>
                  ) : !isSystem && !isEntry ? (
                    <span style={{ color: 'var(--muted)' }}> — {m.text}</span>
                  ) : null}
                </div>
                <div style={{ color: 'var(--muted)', fontSize: 11, marginTop: 2 }}>
                  {m.room_id} · {fmtTime(m.created_at)}
                </div>
              </div>
              <button className="btn btn-danger" style={{ padding: '5px 10px', fontSize: 12 }} onClick={() => remove(m)}>
                حذف
              </button>
            </div>
          );
        })}
        {filtered.length === 0 && <p style={{ color: 'var(--muted)' }}>لا رسائل في هذه الغرفة</p>}
      </div>
    </div>
  );
}
