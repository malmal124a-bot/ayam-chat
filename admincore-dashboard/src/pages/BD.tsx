import { useEffect, useState } from 'react';
import { BDModel } from '../types';
import { getBDs } from '../lib/db';
import DataTable from '../components/DataTable';

export default function BDPage() {
  const [bds, setBds] = useState<BDModel[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getBDs().then(data => { setBds(data); setLoading(false); });
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-white text-lg font-semibold">Business Development (BD)</h2>
        <p className="text-slate-500 text-xs mt-0.5">{bds.length} partners</p>
      </div>
      <DataTable
        loading={loading}
        columns={[
          { key: 'name', label: 'Partner', sortable: true },
          { key: 'region', label: 'Region', sortable: true },
          { key: 'contactName', label: 'Contact' },
          { key: 'contactEmail', label: 'Email' },
          { key: 'dealValue', label: 'Deal Value', sortable: true, render: b => <span className="text-emerald-400">${b.dealValue.toLocaleString()}</span> },
          { key: 'status', label: 'Status', sortable: true, render: b => <span className={b.status === 'active' ? 'text-emerald-400' : 'text-slate-500'}>{b.status}</span> },
        ]}
        data={bds}
        searchKeys={['name', 'region', 'contactName']}
      />
    </div>
  );
}
