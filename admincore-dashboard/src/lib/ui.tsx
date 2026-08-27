import { createContext, useCallback, useContext, useState, type ReactNode } from 'react';

export function cx(...parts: (string | false | null | undefined)[]): string {
  return parts.filter(Boolean).join(' ');
}

export function fmtNumber(n: number): string {
  return new Intl.NumberFormat('en-US').format(n);
}

export function fmtTime(iso: string | null): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  const now = Date.now();
  const diff = now - d.getTime();
  if (diff < 60_000) return 'الآن';
  if (diff < 3_600_000) return `${Math.floor(diff / 60_000)} د`;
  if (diff < 86_400_000) return `${Math.floor(diff / 3_600_000)} س`;
  return d.toLocaleString('ar-EG', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
}

export function fmtDate(iso: string | null): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleString('ar-EG', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

// ---------- Toast ----------
interface ToastCtx {
  push: (msg: string, kind?: 'ok' | 'err') => void;
}
const ToastContext = createContext<ToastCtx>({ push: () => {} });
export const useToast = () => useContext(ToastContext);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<{ id: number; msg: string; kind: string }[]>([]);

  const push = useCallback((msg: string, kind: 'ok' | 'err' = 'ok') => {
    const id = Date.now() + Math.random();
    setItems((prev) => [...prev, { id, msg, kind }]);
    setTimeout(() => setItems((prev) => prev.filter((t) => t.id !== id)), 3200);
  }, []);

  return (
    <ToastContext.Provider value={{ push }}>
      {children}
      <div style={{ position: 'fixed', bottom: 24, right: 24, zIndex: 100, display: 'flex', flexDirection: 'column', gap: 10 }}>
        {items.map((t) => (
          <div key={t.id} className="toast" style={{ position: 'static', width: 'auto', margin: 0 }}>
            <span style={{ color: t.kind === 'err' ? 'var(--red)' : 'var(--green)', fontWeight: 900 }}>
              {t.kind === 'err' ? '✕' : '✓'}
            </span>
            {t.msg}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

// ---------- Spinner ----------
export function Spinner() {
  return <div className="spin" />;
}

export function FullSpinner() {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 60 }}>
      <Spinner />
    </div>
  );
}

// ---------- Modal ----------
export function Modal({
  title,
  onClose,
  children,
  wide,
}: {
  title: string;
  onClose: () => void;
  children: ReactNode;
  wide?: boolean;
}) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div
        className="modal fade-in"
        style={{ maxWidth: wide ? 760 : 560 }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h2 style={{ margin: 0, fontSize: 18, fontWeight: 800, color: 'var(--gold)' }}>{title}</h2>
          <button className="btn btn-ghost" style={{ padding: '6px 12px' }} onClick={onClose}>
            ✕
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

// ---------- Badge ----------
export function Badge({ kind, children }: { kind: string; children: ReactNode }) {
  return <span className={cx('badge', `badge-${kind}`)}>{children}</span>;
}

// ---------- Field ----------
export function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label style={{ display: 'block', marginBottom: 12 }}>
      <div style={{ marginBottom: 6, color: 'var(--muted)', fontWeight: 700, fontSize: 12 }}>{label}</div>
      {children}
    </label>
  );
}

// ---------- Toggle ----------
export function Toggle({ checked, onChange }: { checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      type="button"
      onClick={() => onChange(!checked)}
      style={{
        width: 44,
        height: 24,
        borderRadius: 999,
        background: checked ? 'linear-gradient(135deg,var(--gold),var(--gold-2))' : '#243350',
        border: 'none',
        cursor: 'pointer',
        position: 'relative',
        transition: 'background 0.15s',
      }}
    >
      <span
        style={{
          position: 'absolute',
          top: 3,
          right: checked ? 3 : 23,
          width: 18,
          height: 18,
          borderRadius: '50%',
          background: '#fff',
          transition: 'right 0.15s',
        }}
      />
    </button>
  );
}

// ---------- Search input ----------
export function SearchBox({ value, onChange, placeholder }: { value: string; onChange: (v: string) => void; placeholder?: string }) {
  return (
    <div style={{ position: 'relative', flex: 1, maxWidth: 320 }}>
      <span style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--muted)' }}>🔍</span>
      <input
        className="input"
        style={{ paddingRight: 36 }}
        placeholder={placeholder || 'بحث...'}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  );
}

export function PageHeader({ title, subtitle, actions }: { title: string; subtitle?: string; actions?: ReactNode }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12, marginBottom: 18, flexWrap: 'wrap' }}>
      <div>
        <h1 style={{ margin: 0, fontSize: 22, fontWeight: 800 }}>{title}</h1>
        {subtitle && <p style={{ margin: '4px 0 0', color: 'var(--muted)', fontSize: 13 }}>{subtitle}</p>}
      </div>
      {actions}
    </div>
  );
}
