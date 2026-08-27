import { ChevronDown, Search, X } from 'lucide-react';
import { useState, useMemo, ReactNode } from 'react';

interface Column<T> {
  key: string;
  label: string;
  render?: (item: T) => ReactNode;
  sortable?: boolean;
  width?: string;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  onEdit?: (item: T) => void;
  onDelete?: (item: T) => void;
  searchKeys?: (keyof T)[];
  loading?: boolean;
}

export default function DataTable<T>({
  columns, data, onEdit, onDelete, searchKeys, loading,
}: DataTableProps<T>) {
  const [search, setSearch] = useState('');
  const [sortKey, setSortKey] = useState<string | null>(null);
  const [sortAsc, setSortAsc] = useState(true);
  const [page, setPage] = useState(1);
  const pageSize = 20;

  const filtered = useMemo(() => {
    if (!search.trim() || !searchKeys) return data;
    const q = search.toLowerCase();
    return data.filter((item: T) =>
      (searchKeys as (keyof T)[]).some(key => String((item as Record<string, unknown>)[key as string] ?? '').toLowerCase().includes(q))
    );
  }, [data, search, searchKeys]);

  const sorted = useMemo(() => {
    if (!sortKey) return filtered;
    return [...filtered].sort((a, b) => {
      const aVal = (a as Record<string, unknown>)[sortKey];
      const bVal = (b as Record<string, unknown>)[sortKey];
      if (aVal == null || bVal == null) return 0;
      const cmp = String(aVal).localeCompare(String(bVal), undefined, { numeric: true });
      return sortAsc ? cmp : -cmp;
    });
  }, [filtered, sortKey, sortAsc]);

  const totalPages = Math.ceil(sorted.length / pageSize);
  const paged = sorted.slice((page - 1) * pageSize, page * pageSize);

  const toggleSort = (key: string) => {
    if (sortKey === key) setSortAsc(a => !a);
    else { setSortKey(key); setSortAsc(true); }
  };

  return (
    <div className="bg-[#141417] rounded-2xl border border-white/5">
      <div className="p-4 border-b border-white/5 flex items-center gap-3">
        <div className="relative flex-1 max-w-xs">
          <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none" />
          <input
            type="text" value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
            placeholder="Search..."
            className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 pl-9 pr-8 text-xs text-white focus:outline-none focus:border-indigo-500 placeholder:text-slate-600"
          />
          {search && (
            <button onClick={() => setSearch('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white">
              <X className="w-3 h-3" />
            </button>
          )}
        </div>
        <span className="text-[10px] text-slate-500">{sorted.length} items</span>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-xs">
          <thead>
            <tr className="border-b border-white/5">
              {columns.map(col => (
                <th
                  key={col.key}
                  className={`text-left text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3 ${col.sortable ? 'cursor-pointer hover:text-white' : ''}`}
                  style={{ width: col.width }}
                  onClick={() => col.sortable && toggleSort(col.key)}
                >
                  <span className="flex items-center gap-1">
                    {col.label}
                    {col.sortable && sortKey === col.key && (
                      <ChevronDown className={`w-3 h-3 transition-transform ${sortAsc ? '' : 'rotate-180'}`} />
                    )}
                  </span>
                </th>
              ))}
              {(onEdit || onDelete) && <th className="text-right text-[10px] uppercase tracking-wider text-slate-500 font-bold p-3 w-20">Actions</th>}
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={columns.length + 1} className="text-center py-12 text-slate-500">Loading...</td></tr>
            ) : paged.length === 0 ? (
              <tr><td colSpan={columns.length + 1} className="text-center py-12 text-slate-500">No data found</td></tr>
            ) : (
              paged.map((item, idx) => (
                <tr key={idx} className="border-b border-white/5 hover:bg-white/5 transition-colors">
                  {columns.map(col => (
                    <td key={col.key} className="p-3 text-white">
                      {col.render ? col.render(item) : String((item as Record<string, unknown>)[col.key] ?? '')}
                    </td>
                  ))}
                  {(onEdit || onDelete) && (
                    <td className="p-3 text-right sticky right-0 bg-[#141417] shadow-[-8px_0_12px_-6px_rgba(0,0,0,0.5)]">
                      <div className="flex items-center justify-end gap-2">
                        {onEdit && (
                          <button onClick={() => onEdit(item)} className="text-[10px] text-indigo-400 hover:text-indigo-300 font-semibold">Edit</button>
                        )}
                        {onDelete && (
                          <button onClick={() => onDelete(item)} className="text-[10px] text-rose-400 hover:text-rose-300 font-semibold">Delete</button>
                        )}
                      </div>
                    </td>
                  )}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
      {totalPages > 1 && (
        <div className="p-3 border-t border-white/5 flex items-center justify-between text-xs text-slate-500">
          <button disabled={page <= 1} onClick={() => setPage(p => p - 1)} className="px-2 py-1 rounded hover:bg-white/5 disabled:opacity-30">Prev</button>
          <span>Page {page} of {totalPages}</span>
          <button disabled={page >= totalPages} onClick={() => setPage(p => p + 1)} className="px-2 py-1 rounded hover:bg-white/5 disabled:opacity-30">Next</button>
        </div>
      )}
    </div>
  );
}
