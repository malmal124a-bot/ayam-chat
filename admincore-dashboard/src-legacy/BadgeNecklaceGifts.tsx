import { useEffect, useState } from 'react';
import { UserModel, BadgeConfig, NecklaceConfig } from '../types';
import { getUsers, getBadges, getNecklaces, updateUser, getUser } from '../lib/db';
import DataTable from '../components/DataTable';
import { Award, Crown, Send, X } from 'lucide-react';

export default function BadgeNecklaceGifts() {
  const [users, setUsers] = useState<UserModel[]>([]);
  const [badges, setBadges] = useState<BadgeConfig[]>([]);
  const [necklaces, setNecklaces] = useState<NecklaceConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<UserModel | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [giftType, setGiftType] = useState<'badge' | 'necklace'>('badge');
  const [selectedBadge, setSelectedBadge] = useState<string>('');
  const [selectedNecklace, setSelectedNecklace] = useState<string>('');
  const [msg, setMsg] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const [u, b, n] = await Promise.all([getUsers(), getBadges(), getNecklaces()]);
      setUsers(u);
      setBadges(b.filter(badge => badge.type === 'admin'));
      setNecklaces(n.filter(necklace => necklace.type === 'admin' || necklace.type === 'event'));
    } finally {
      setLoading(false);
    }
  };
  useEffect(() => { load(); }, []);

  const showMsg = (text: string) => { setMsg(text); setTimeout(() => setMsg(''), 3000); };

  const handleSelectUser = (user: UserModel) => {
    setSelectedUser(user);
    setShowModal(true);
    setGiftType('badge');
    setSelectedBadge('');
    setSelectedNecklace('');
  };

  const handleSendGift = async () => {
    if (!selectedUser) return;
    if (giftType === 'badge' && !selectedBadge) return;
    if (giftType === 'necklace' && !selectedNecklace) return;

    try {
      // Get the user's current data
      const currentUser = await getUser(selectedUser.uid);
      
      if (giftType === 'badge') {
        // Add badge to ownedBadges
        const newOwnedBadges = [...(currentUser?.ownedBadges || []), selectedBadge];
        // Remove duplicates
        const uniqueBadges = [...new Set(newOwnedBadges)];
        await updateUser(selectedUser.uid, { ownedBadges: uniqueBadges });
      } else if (giftType === 'necklace') {
        // Add necklace to ownedNecklaces
        const newOwnedNecklaces = [...(currentUser?.ownedNecklaces || []), selectedNecklace];
        // Remove duplicates
        const uniqueNecklaces = [...new Set(newOwnedNecklaces)];
        await updateUser(selectedUser.uid, { ownedNecklaces: uniqueNecklaces });
      }

      showMsg('Gift sent successfully!');
      setShowModal(false);
      setSelectedUser(null);
      // Refresh the user list
      await load();
    } catch (error: unknown) {
      console.error('Failed to send gift:', error);
      const err = error as { message?: string; details?: string; hint?: string };
      showMsg('Failed to send gift: ' + (err?.message ?? err?.details ?? 'Unknown error'));
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-white text-lg font-semibold">Badge & Necklace Gifts</h2>
        <p className="text-slate-500 text-xs mt-0.5">Send badges and necklaces to users</p>
      </div>

      {msg && <div className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs px-4 py-2 rounded-lg">{msg}</div>}

      <DataTable
        loading={loading}
        columns={[
          { key: 'name', label: 'User', sortable: true, render: u => (
            <div className="flex items-center gap-2">
              {u.photoUrl ? <img src={u.photoUrl} className="w-8 h-8 rounded-full object-cover" /> : <div className="w-8 h-8 rounded-full bg-slate-700" />}
              <div className="flex flex-col">
                <span className="text-sm font-medium">{u.name}</span>
                <span className="text-[10px] text-slate-500">{u.email}</span>
              </div>
            </div>
          )},
          { key: 'email', label: 'Email', sortable: true },
          { key: 'actions', label: '', width: '100px', render: u => (
            <button onClick={() => handleSelectUser(u)} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
              <Send className="w-3 h-3" /> Send Gift
            </button>
          )}
        ]}
        data={users}
        searchKeys={['name', 'email', 'customId']}
      />

      {showModal && selectedUser && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="bg-[#141417] rounded-2xl border border-white/10 p-6 w-full max-w-md space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-white font-semibold">Send Gift to {selectedUser.name}</h3>
              <button onClick={() => setShowModal(false)} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
            </div>

            <div className="flex gap-2 border border-white/10 rounded-lg p-1">
              <button
                onClick={() => setGiftType('badge')}
                className={`flex-1 py-2 px-3 rounded-md text-xs font-semibold flex items-center justify-center gap-1 ${
                  giftType === 'badge' ? 'bg-indigo-600 text-white' : 'text-slate-400 hover:bg-white/5'
                }`}
              >
                <Award className="w-3 h-3" /> Badge
              </button>
              <button
                onClick={() => setGiftType('necklace')}
                className={`flex-1 py-2 px-3 rounded-md text-xs font-semibold flex items-center justify-center gap-1 ${
                  giftType === 'necklace' ? 'bg-indigo-600 text-white' : 'text-slate-400 hover:bg-white/5'
                }`}
              >
                <Crown className="w-3 h-3" /> Necklace
              </button>
            </div>

            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-2">
                Select {giftType === 'badge' ? 'Badge' : 'Necklace'}
              </label>
              {giftType === 'badge' ? (
                <select
                  value={selectedBadge}
                  onChange={(e) => setSelectedBadge(e.target.value)}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white"
                >
                  <option value="">Select Badge</option>
                  {badges.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
                </select>
              ) : (
                <select
                  value={selectedNecklace}
                  onChange={(e) => setSelectedNecklace(e.target.value)}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white"
                >
                  <option value="">Select Necklace</option>
                  {necklaces.map(n => <option key={n.id} value={n.id}>{n.name} ({n.type})</option>)}
                </select>
              )}
            </div>

            <div className="flex gap-2">
              <button onClick={() => setShowModal(false)} className="flex-1 py-2 px-3 bg-slate-700 hover:bg-slate-600 text-xs text-white font-semibold rounded-lg">
                Cancel
              </button>
              <button
                onClick={handleSendGift}
                disabled={giftType === 'badge' ? !selectedBadge : !selectedNecklace}
                className="flex-1 py-2 px-3 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-xs text-white font-semibold rounded-lg flex items-center justify-center gap-1"
              >
                <Send className="w-3 h-3" /> Send Gift
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
