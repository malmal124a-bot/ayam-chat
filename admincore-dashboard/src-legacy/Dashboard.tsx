import { useEffect, useState } from 'react';
import { Users, DoorOpen, Gift, DollarSign, TrendingUp, Activity } from 'lucide-react';
import { getStats } from '../lib/db';

export default function Dashboard() {
  const [stats, setStats] = useState({ totalUsers: 0, totalRooms: 0, totalGifts: 0, totalRevenue: 0 });

  useEffect(() => {
    getStats().then(setStats);
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-white text-lg font-semibold">Dashboard</h2>
        <p className="text-slate-500 text-xs mt-0.5">Real-time overview of your app</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-[#141417] p-5 rounded-2xl border border-white/5 hover:border-white/10 transition-colors">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-9 h-9 rounded-xl bg-indigo-500/10 flex items-center justify-center text-indigo-400">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-bold font-mono text-white">{stats.totalUsers}</div>
          <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mt-1">Total Users</div>
        </div>

        <div className="bg-[#141417] p-5 rounded-2xl border border-white/5 hover:border-white/10 transition-colors">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-9 h-9 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-400">
              <DoorOpen className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-bold font-mono text-white">{stats.totalRooms}</div>
          <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mt-1">Total Rooms</div>
        </div>

        <div className="bg-[#141417] p-5 rounded-2xl border border-white/5 hover:border-white/10 transition-colors">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-9 h-9 rounded-xl bg-rose-500/10 flex items-center justify-center text-rose-400">
              <Gift className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-bold font-mono text-white">{stats.totalGifts}</div>
          <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mt-1">Gift Types</div>
        </div>

        <div className="bg-[#141417] p-5 rounded-2xl border border-white/5 hover:border-white/10 transition-colors">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-9 h-9 rounded-xl bg-amber-500/10 flex items-center justify-center text-amber-400">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-bold font-mono text-white">${stats.totalRevenue.toLocaleString()}</div>
          <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mt-1">Total Gift Value</div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-[#141417] rounded-2xl border border-white/5 p-6">
          <h3 className="text-white text-sm font-semibold mb-4 flex items-center gap-2">
            <Activity className="w-4 h-4 text-indigo-400" />
            Quick Actions
          </h3>
          <div className="grid grid-cols-2 gap-3">
            {[
              { label: 'Browse Users', icon: Users, color: 'text-indigo-400', bg: 'bg-indigo-500/10' },
              { label: 'View Rooms', icon: DoorOpen, color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
              { label: 'Manage Gifts', icon: Gift, color: 'text-rose-400', bg: 'bg-rose-500/10' },
              { label: 'Revenue Report', icon: TrendingUp, color: 'text-amber-400', bg: 'bg-amber-500/10' },
            ].map(action => (
              <div key={action.label} className={`${action.bg} rounded-xl p-4 flex items-center gap-3 cursor-pointer hover:brightness-110 transition-all`}>
                <action.icon className={`w-5 h-5 ${action.color}`} />
                <span className="text-xs text-white font-medium">{action.label}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-[#141417] rounded-2xl border border-white/5 p-6">
          <h3 className="text-white text-sm font-semibold mb-4">System Info</h3>
          <div className="space-y-3 text-xs">
            {[
              { label: 'Supabase Project', value: 'mnpoiobmargjlnxwczgi' },
              { label: 'DB Region', value: 'auto (Supabase)' },
              { label: 'Auth Provider', value: 'Supabase Auth' },
              { label: 'Storage', value: 'Cloudinary + Supabase' },
            ].map(info => (
              <div key={info.label} className="flex justify-between border-b border-white/5 pb-2">
                <span className="text-slate-500">{info.label}</span>
                <span className="text-white font-mono">{info.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
