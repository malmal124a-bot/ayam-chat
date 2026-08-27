import { useEffect, useState } from 'react';
import { BugReport } from '../types';
import { getBugReports } from '../lib/db';
import DataTable from '../components/DataTable';
import { Bug, AlertTriangle } from 'lucide-react';

export default function ErrorAnalysisPage() {
  const [reports, setReports] = useState<BugReport[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getBugReports().then(data => { setReports(data); setLoading(false); });
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-white text-lg font-semibold">Error Analysis</h2>
        <p className="text-slate-500 text-xs mt-0.5">{reports.length} bug reports</p>
      </div>
      <DataTable
        loading={loading}
        columns={[
          { key: 'id', label: 'ID', render: r => <span className="font-mono text-[10px] text-slate-400">{r.id?.slice(0, 8)}</span> },
          { key: 'message', label: 'Message', render: r => (
            <div className="flex items-center gap-2">
              <AlertTriangle className="w-3.5 h-3.5 text-rose-400 shrink-0" />
              <span className="text-xs truncate max-w-xs">{r.message}</span>
            </div>
          )},
          { key: 'appVersion', label: 'Version', render: r => <span className="text-[10px] text-slate-500">{r.appVersion || '-'}</span> },
          { key: 'timestamp', label: 'Time', sortable: true, render: r => <span className="text-[10px] text-slate-500">{r.timestamp ? new Date(r.timestamp).toLocaleString() : '-'}</span> },
        ]}
        data={reports}
        searchKeys={['message', 'id']}
      />
    </div>
  );
}
