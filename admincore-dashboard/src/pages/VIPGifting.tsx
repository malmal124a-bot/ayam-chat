import { useEffect, useState } from 'react';
import { getUserVIPs, giftVIP, revokeUserVIP, getUsers, getVIPConfig } from '../lib/db';
import type { UserVIP, VIPConfig, UserModel } from '../types';
import { Crown, Search, Gift, X, Clock, User, ShieldAlert } from 'lucide-react';

export default function VIPGifting() {
  const [userVIPs, setUserVIPs] = useState<UserVIP[]>([]);
  const [vipConfigs, setVIPConfigs] = useState<VIPConfig[]>([]);
  const [users, setUsers] = useState<UserModel[]>([]);
  const [search, setSearch] = useState('');
  const [showGiftModal, setShowGiftModal] = useState(false);
  const [giftForm, setGiftForm] = useState({ uid: '', tier: 1, expiryDays: 30 });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    getUserVIPs().then(setUserVIPs);
    getVIPConfig().then(setVIPConfigs);
    getUsers().then(setUsers);
  }, []);

  const refresh = async () => {
    setUserVIPs(await getUserVIPs());
    setVIPConfigs(await getVIPConfig());
  };

  const handleGift = async () => {
    if (!giftForm.uid || !giftForm.tier) return;
    setLoading(true);
    await giftVIP(giftForm.uid, giftForm.tier, 'admin', giftForm.expiryDays || undefined);
    setLoading(false);
    setShowGiftModal(false);
    setGiftForm({ uid: '', tier: 1, expiryDays: 30 });
    refresh();
  };

  const handleRevoke = async (uid: string, tier: number) => {
    await revokeUserVIP(uid, tier);
    refresh();
  };

  const filteredUsers = users.filter(u =>
    u.name?.toLowerCase().includes(search.toLowerCase()) ||
    u.uid?.toLowerCase().includes(search.toLowerCase()) ||
    u.email?.toLowerCase().includes(search.toLowerCase())
  );

  const getVIPName = (tier: number) => {
    const cfg = vipConfigs.find(c => c.tier === tier);
    return cfg ? cfg.name : `VIP ${tier}`;
  };

  const getVIPColor = (tier: number) => {
    const cfg = vipConfigs.find(c => c.tier === tier);
    return cfg?.color || '#DE880F';
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold flex items-center gap-2">
            <Gift className="w-5 h-5 text-emerald-400" />
            VIP Gifting
          </h2>
          <p className="text-slate-500 text-xs mt-0.5">{userVIPs.length} VIP members</p>
        </div>
        <button
          onClick={() => setShowGiftModal(true)}
          className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1.5"
        >
          <Gift className="w-3.5 h-3.5" /> Gift VIP
        </button>
      </div>

      <div className="bg-[#141417] rounded-2xl border border-white/5 overflow-hidden">
        <div className="p-3 border-b border-white/5 flex items-center gap-2">
          <Search className="w-4 h-4 text-slate-500" />
          <input
            type="text"
            placeholder="Search users by name, email or UID..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="flex-1 bg-transparent text-xs text-white placeholder-slate-500 outline-none"
          />
        </div>
        <div className="divide-y divide-white/5">
          {userVIPs.length === 0 ? (
            <div className="p-8 text-center">
              <Crown className="w-8 h-8 text-slate-600 mx-auto mb-2" />
              <p className="text-xs text-slate-500">No VIP members yet. Gift VIP to a user below.</p>
            </div>
          ) : (
            userVIPs.map(vip => {
              const user = users.find(u => u.uid === vip.uid);
              return (
                <div key={`${vip.uid}-${vip.tier}`} className="flex items-center gap-3 px-4 py-3 hover:bg-white/5 transition-colors">
                  <img
                    src={user?.photoUrl || 'https://ui-avatars.com/api/?name=U&background=6366f1&color=fff'}
                    className="w-8 h-8 rounded-full object-cover"
                  />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm text-white font-medium truncate">{user?.name || vip.uid}</span>
                      <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded" style={{ backgroundColor: getVIPColor(vip.tier) + '20', color: getVIPColor(vip.tier) }}>
                        {getVIPName(vip.tier)}
                      </span>
                    </div>
                    <div className="flex items-center gap-3 text-[10px] text-slate-500 mt-0.5">
                      <span className="flex items-center gap-1"><User className="w-3 h-3" />{vip.uid.slice(0, 12)}...</span>
                      <span className="flex items-center gap-1"><Clock className="w-3 h-3" />{new Date(vip.purchased_at).toLocaleDateString()}</span>
                      {vip.expires_at && <span className="text-amber-400">Expires: {new Date(vip.expires_at).toLocaleDateString()}</span>}
                      {vip.gifted_by && <span className="text-indigo-400">Gifted by {vip.gifted_by}</span>}
                    </div>
                  </div>
                  <button
                    onClick={() => handleRevoke(vip.uid, vip.tier)}
                    className="p-1.5 rounded-lg text-slate-500 hover:text-rose-400 hover:bg-rose-500/10 transition-colors"
                    title="Revoke VIP"
                  >
                    <ShieldAlert className="w-4 h-4" />
                  </button>
                </div>
              );
            })
          )}
        </div>
      </div>

      {showGiftModal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50" onClick={() => setShowGiftModal(false)}>
          <div className="bg-[#141417] rounded-2xl border border-white/10 p-6 w-full max-w-lg mx-4 space-y-4" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="text-white font-semibold text-sm flex items-center gap-2"><Gift className="w-4 h-4 text-emerald-400" /> Gift VIP</h3>
              <button onClick={() => setShowGiftModal(false)} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
            </div>

            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Select User</label>
              <div className="relative">
                <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-500" />
                <input
                  type="text" placeholder="Search users..."
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 pl-8 pr-2 text-xs text-white"
                />
              </div>
              <div className="mt-2 max-h-40 overflow-y-auto space-y-1">
                {filteredUsers.slice(0, 10).map(u => (
                  <button
                    key={u.uid}
                    onClick={() => setGiftForm(p => ({ ...p, uid: u.uid }))}
                    className={`w-full flex items-center gap-2 px-2 py-1.5 rounded-lg text-xs transition-colors ${
                      giftForm.uid === u.uid ? 'bg-indigo-500/20 text-indigo-300' : 'text-slate-400 hover:bg-white/5'
                    }`}
                  >
                    <img src={u.photoUrl || 'https://ui-avatars.com/api/?name=U&background=6366f1&color=fff'} className="w-6 h-6 rounded-full" />
                    <span className="truncate">{u.name || u.uid.slice(0, 12)}</span>
                    <span className="text-[9px] text-slate-600 truncate">{u.email}</span>
                  </button>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">VIP Tier</label>
                <select
                  value={giftForm.tier}
                  onChange={e => setGiftForm(p => ({ ...p, tier: Number(e.target.value) }))}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
                >
                  {vipConfigs.map(v => (
                    <option key={v.tier} value={v.tier}>{v.name} (Tier {v.tier})</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Expiry (days)</label>
                <input
                  type="number"
                  value={giftForm.expiryDays}
                  onChange={e => setGiftForm(p => ({ ...p, expiryDays: Number(e.target.value) }))}
                  placeholder="Leave empty for permanent"
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
                />
              </div>
            </div>

            <div className="flex gap-2 pt-2">
              <button
                onClick={handleGift}
                disabled={loading || !giftForm.uid}
                className="flex-1 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-xs text-white font-semibold rounded-lg flex items-center justify-center gap-1"
              >
                {loading ? 'Gifting...' : <><Gift className="w-3.5 h-3.5" /> Gift VIP</>}
              </button>
              <button onClick={() => setShowGiftModal(false)} className="px-4 py-2 border border-white/10 text-xs text-slate-400 rounded-lg">Cancel</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
