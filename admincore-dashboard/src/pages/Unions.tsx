import { useEffect, useState } from 'react';
import { UnionModel } from '../types';
import { getUnions } from '../lib/db';
import DataTable from '../components/DataTable';
import { Building2 } from 'lucide-react';

export default function UnionsPage() {
  const [unions, setUnions] = useState<UnionModel[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getUnions().then(data => { setUnions(data); setLoading(false); });
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-white text-lg font-semibold">Union Management</h2>
        <p className="text-slate-500 text-xs mt-0.5">{unions.length} total unions</p>
      </div>
      <DataTable
        loading={loading}
        columns={[
          { key: 'id', label: 'ID', render: u => <span className="font-mono text-[10px] text-slate-400">{u.id}</span> },
          { key: 'name', label: 'Name', sortable: true, render: u => (
            <div className="flex items-center gap-2">
              {u.logoUrl ? <img src={u.logoUrl} className="w-6 h-6 rounded-full object-cover" /> : <Building2 className="w-5 h-5 text-slate-500" />}
              <div>
                <div className="text-white text-xs">{u.name}</div>
                <div className="text-[10px] text-slate-500">{u.creatorName}</div>
              </div>
            </div>
          )},
          { key: 'level', label: 'Level', sortable: true },
          { key: 'memberCount', label: 'Members', sortable: true },
          { key: 'createdAt', label: 'Created', sortable: true, render: u => <span className="text-[10px] text-slate-500">{new Date(u.createdAt).toLocaleDateString()}</span> },
        ]}
        data={unions}
        searchKeys={['name', 'creatorName', 'id']}
      />
    </div>
  );
}
