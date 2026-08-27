import { useEffect, useMemo, useState } from 'react';
import { listDMs } from '../lib/api';
import { supabase } from '../lib/supabase';
import type { DmMessageRow } from '../lib/types';
import { Badge, FullSpinner, PageHeader, fmtTime } from '../lib/ui';

interface Thread {
  partnerId: string;
  partnerName: string;
  messages: DmMessageRow[];
}

export default function DMs() {
  const [all, setAll] = useState<DmMessageRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [active, setActive] = useState<string | null>(null);

  useEffect(() => {
    const load = () => {
      listDMs(500)
        .then(setAll)
        .catch(() => {})
        .finally(() => setLoading(false));
    };
    load();
    const sub = supabase
      .channel('dashboard-dms')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'dm_messages' }, load)
      .subscribe();
    return () => {
      supabase.removeChannel(sub);
    };
  }, []);

  const threads = useMemo(() => {
    const map = new Map<string, Thread>();
    for (const m of all) {
      const key = [m.from_user_id, m.to_user_id].sort().join('|');
      if (!map.has(key)) {
        map.set(key, { partnerId: m.from_user_id, partnerName: m.from_name || m.to_name || 'محادثة', messages: [] });
      }
      map.get(key)!.messages.push(m);
    }
    const list = Array.from(map.values());
    list.sort((a, b) => (b.messages[b.messages.length - 1].created_at || '').localeCompare(a.messages[a.messages.length - 1].created_at || ''));
    return list;
  }, [all]);

  const activeThread = active ? threads.find((t) => t.partnerId === active) : null;

  if (loading) return <FullSpinner />;

  return (
    <div>
      <PageHeader title="الرسائل الخاصة" subtitle="قراءة بث حي لجدول dm_messages بين المستخدمين" />
      <div style={{ display: 'grid', gridTemplateColumns: '300px 1fr', gap: 16 }} className="resp-grid">
        <div className="card" style={{ padding: 10, maxHeight: 'calc(100vh - 140px)', overflow: 'auto' }}>
          {threads.map((t) => {
            const unread = t.messages.filter((m) => !m.is_read).length;
            return (
              <button
                key={t.partnerId}
                onClick={() => setActive(t.partnerId)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 10,
                  width: '100%',
                  padding: '10px 12px',
                  borderRadius: 10,
                  border: 'none',
                  background: active === t.partnerId ? 'rgba(245,185,66,0.12)' : 'transparent',
                  color: 'var(--text)',
                  cursor: 'pointer',
                  fontFamily: 'inherit',
                  marginBottom: 2,
                }}
              >
                <div
                  style={{
                    width: 36,
                    height: 36,
                    borderRadius: '50%',
                    background: 'linear-gradient(135deg,#3b82f6,#a855f7)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: 14,
                    fontWeight: 800,
                    flexShrink: 0,
                  }}
                >
                  {t.partnerName.charAt(0)}
                </div>
                <div style={{ flex: 1, minWidth: 0, textAlign: 'right' }}>
                  <div style={{ fontWeight: 700, fontSize: 13 }}>{t.partnerName}</div>
                  <div style={{ color: 'var(--muted)', fontSize: 11, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {t.messages[t.messages.length - 1].text}
                  </div>
                </div>
                {unread > 0 && (
                  <span
                    style={{
                      background: 'var(--gold)',
                      color: '#1a1202',
                      borderRadius: 999,
                      minWidth: 20,
                      height: 20,
                      fontSize: 11,
                      fontWeight: 800,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      padding: '0 6px',
                    }}
                  >
                    {unread}
                  </span>
                )}
              </button>
            );
          })}
          {threads.length === 0 && <p style={{ color: 'var(--muted)', textAlign: 'center', padding: 20 }}>لا رسائل خاصة بعد</p>}
        </div>

        <div className="card" style={{ padding: 20, maxHeight: 'calc(100vh - 140px)', overflow: 'auto' }}>
          {!activeThread ? (
            <p style={{ color: 'var(--muted)', textAlign: 'center', padding: 40 }}>اختر محادثة لعرض الرسائل</p>
          ) : (
            <>
              <div style={{ marginBottom: 14, display: 'flex', alignItems: 'center', gap: 10 }}>
                <Badge kind="blue">{activeThread.messages.length} رسالة</Badge>
                <span style={{ color: 'var(--muted)', fontSize: 12 }}>{activeThread.partnerId}</span>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {activeThread.messages.map((m) => (
                  <div
                    key={m.id}
                    style={{
                      alignSelf: m.from_user_id === activeThread.partnerId ? 'flex-start' : 'flex-end',
                      maxWidth: '75%',
                    }}
                  >
                    <div className={m.from_user_id === activeThread.partnerId ? 'chat-bubble-other' : 'chat-bubble-me'}>
                      {m.text}
                    </div>
                    <div style={{ color: 'var(--muted)', fontSize: 10, marginTop: 3, textAlign: 'center' }}>
                      {m.from_name} · {fmtTime(m.created_at)}
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
