import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { fetchStats } from '../lib/api';
import type { Stats, MessageRow, UserRow } from '../lib/types';
import { Badge, FullSpinner, PageHeader, fmtNumber, fmtTime } from '../lib/ui';

export default function Overview() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [feed, setFeed] = useState<MessageRow[]>([]);
  const [users, setUsers] = useState<UserRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats().then(setStats).catch(() => setStats(null));

    supabase
      .from('messages')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(12)
      .then(({ data }) => setFeed((data ?? []) as MessageRow[]));

    supabase
      .from('users')
      .select('auth_uid,name,photo_url,vip_level,level,is_online,created_at')
      .order('created_at', { ascending: false })
      .limit(8)
      .then(({ data }) => setUsers((data ?? []) as UserRow[]));

    const sub = supabase
      .channel('dashboard-live')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages' }, (payload) => {
        setFeed((prev) => {
          const next = [payload.new as MessageRow, ...prev];
          return next.slice(0, 12);
        });
        setStats((s) => (s ? { ...s, messages: s.messages + 1 } : s));
      })
      .subscribe();

    setLoading(false);
    return () => {
      supabase.removeChannel(sub);
    };
  }, []);

  const cards = [
    { label: 'المستخدمون', value: stats?.users ?? 0, icon: '👥', color: '#3b82f6' },
    { label: 'الغرف', value: stats?.rooms ?? 0, icon: '🏠', color: '#a855f7' },
    { label: 'رسائل الغرف', value: stats?.messages ?? 0, icon: '💬', color: '#2ec27e' },
    { label: 'الرسائل الخاصة', value: stats?.dms ?? 0, icon: '✉️', color: '#f5b942' },
    { label: 'الهدايا المرسلة', value: stats?.giftsSent ?? 0, icon: '🎁', color: '#ef5350' },
    { label: 'ماس دائمون', value: stats?.participants ?? 0, icon: '🎧', color: '#22d3ee' },
    { label: 'الماس المُنفق', value: stats?.diamondsSpent ?? 0, icon: '💎', color: '#60a5fa' },
    { label: 'أونلاين الآن', value: stats?.onlineUsers ?? 0, icon: '🟢', color: '#4ade80' },
  ];

  return (
    <div>
      <PageHeader
        title="نظرة عامة"
        subtitle="بيانات حية من تطبيق Ayam Chat — تتحدث مباشرة"
      />

      {loading && !stats ? (
        <FullSpinner />
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(180px,1fr))', gap: 14 }}>
          {cards.map((c) => (
            <div className="stat-card" key={c.label}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ color: 'var(--muted)', fontSize: 12, fontWeight: 700 }}>{c.label}</div>
                  <div style={{ fontSize: 26, fontWeight: 900, marginTop: 4 }}>{fmtNumber(c.value)}</div>
                </div>
                <div className="icon" style={{ background: `${c.color}22`, color: c.color }}>
                  {c.icon}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18, marginTop: 22 }} className="resp-grid">
        <div className="card" style={{ padding: 20 }}>
          <h3 style={{ margin: '0 0 14px', fontSize: 16, fontWeight: 800, color: 'var(--gold)' }}>🕐 آخر الرسائل الحية</h3>
          {feed.length === 0 ? (
            <p style={{ color: 'var(--muted)' }}>لا رسائل بعد</p>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {feed.map((m) => (
                <div key={m.id} style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
                  <span className={`badge ${m.type === 'gift' ? 'badge-gold' : m.type === 'system' ? 'badge-purple' : m.type === 'entryEffect' ? 'badge-blue' : 'badge-gray'}`}>
                    {m.type === 'gift' ? '🎁 هدية' : m.type === 'system' ? '⚙️ نظام' : m.type === 'entryEffect' ? '✨ دخول' : '💬'}
                  </span>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13 }}>
                      <b>{m.sender_name || 'مجهول'}</b>
                      {m.gift_name ? (
                        <span style={{ color: 'var(--gold)' }}> أرسل {m.gift_name}{m.gift_count && m.gift_count > 1 ? ` x${m.gift_count}` : ''}</span>
                      ) : (
                        <span style={{ color: 'var(--muted)' }}> — {m.text}</span>
                      )}
                    </div>
                    <div style={{ color: 'var(--muted)', fontSize: 11, marginTop: 2 }}>
                      {m.room_id} · {fmtTime(m.created_at)}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="card" style={{ padding: 20 }}>
          <h3 style={{ margin: '0 0 14px', fontSize: 16, fontWeight: 800, color: 'var(--gold)' }}>👥 أحدث المسجلين</h3>
          {users.length === 0 ? (
            <p style={{ color: 'var(--muted)' }}>لا مستخدمين</p>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {users.map((u) => (
                <div key={u.auth_uid} style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                  <img
                    src={u.photo_url || 'https://www.gravatar.com/avatar/?d=mp'}
                    alt=""
                    style={{ width: 34, height: 34, borderRadius: '50%', objectFit: 'cover', background: '#243350' }}
                    onError={(e) => ((e.target as HTMLImageElement).src = 'https://www.gravatar.com/avatar/?d=mp')}
                  />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 700 }}>{u.name || 'مستخدم'}</div>
                    <div style={{ color: 'var(--muted)', fontSize: 11 }}>
                      لفل {u.level} · VIP {u.vip_level} · {fmtTime(u.created_at)}
                    </div>
                  </div>
                  <Badge kind={u.is_online ? 'green' : 'gray'}>{u.is_online ? 'أونلاين' : 'أوفلاين'}</Badge>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
