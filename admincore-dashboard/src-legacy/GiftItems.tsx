import { useEffect, useState, useContext } from 'react';
import { UserModel, StoreItemModel, GiftedItem } from '../types';
import { getUsers } from '../lib/db';
import { getStoreItems } from '../lib/db';
import { getGiftedItems, sendGiftedItem, revokeGiftedItem, subscribeGiftedItems } from '../lib/db';
import DataTable from '../components/DataTable';
import { Plus, X, Send, Clock, AlertTriangle } from 'lucide-react';
import { I18nContext } from '../lib/i18n';

export default function GiftItemsPage() {
  const [giftedItems, setGiftedItems] = useState<GiftedItem[]>([]);
  const [users, setUsers] = useState<UserModel[]>([]);
  const [storeItems, setStoreItems] = useState<StoreItemModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [showSend, setShowSend] = useState(false);
  const [searchUser, setSearchUser] = useState('');
  const [selectedUser, setSelectedUser] = useState<UserModel | null>(null);
  const [selectedItem, setSelectedItem] = useState<StoreItemModel | null>(null);
  const [expiryDays, setExpiryDays] = useState(7);
  const [sending, setSending] = useState(false);
  const [storeSearch, setStoreSearch] = useState('');
  const { t, lang } = useContext(I18nContext);

  useEffect(() => {
    getUsers().then(setUsers);
    getStoreItems().then(setStoreItems);
    const unsub = subscribeGiftedItems(list => {
      list.sort((a, b) => b.sentAt - a.sentAt);
      setGiftedItems(list);
      setLoading(false);
    });
    return unsub;
  }, []);

  const filteredUsers = searchUser
    ? users.filter(u =>
        u.name?.toLowerCase().includes(searchUser.toLowerCase()) ||
        u.uid?.toLowerCase().includes(searchUser.toLowerCase()) ||
        u.customId?.toLowerCase().includes(searchUser.toLowerCase())
      ).slice(0, 10)
    : [];

  const filteredStore = storeSearch
    ? storeItems.filter(s =>
        s.name?.toLowerCase().includes(storeSearch.toLowerCase()) ||
        s.itemId?.toLowerCase().includes(storeSearch.toLowerCase()) ||
        s.category?.toLowerCase().includes(storeSearch.toLowerCase())
      ).slice(0, 10)
    : storeItems;

  const handleSend = async () => {
    if (!selectedUser || !selectedItem) return;
    setSending(true);
    try {
      await sendGiftedItem(selectedUser.uid, selectedItem, 'admin', 'Admin', expiryDays);
      setShowSend(false);
      setSelectedUser(null);
      setSelectedItem(null);
      setSearchUser('');
      setStoreSearch('');
    } catch (err) {
      alert('Failed to send: ' + (err as Error).message);
    }
    setSending(false);
  };

  const handleRevoke = async (item: GiftedItem) => {
    if (confirm(`Revoke "${item.itemName}" from user ${item.uid}?`)) {
      await revokeGiftedItem(item.id);
    }
  };

  const now = Date.now();

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">Gifted Items</h2>
          <p className="text-slate-500 text-xs mt-0.5">{giftedItems.length} items sent</p>
        </div>
        <button onClick={() => { setShowSend(!showSend); setSelectedUser(null); setSelectedItem(null); }} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
          <Plus className="w-3.5 h-3.5" /> {showSend ? 'Cancel' : 'Send Item'}
        </button>
      </div>

      {showSend && (
        <div className="bg-[#141417] rounded-2xl border border-indigo-500/20 p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-white font-semibold text-sm">Send Store Item to User</h3>
            <button onClick={() => setShowSend(false)} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* User select */}
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">User</label>
              <input
                type="text"
                value={searchUser}
                onChange={e => setSearchUser(e.target.value)}
                placeholder="Search by name, UID, or custom ID..."
                className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
              />
              {selectedUser && (
                <div className="mt-2 flex items-center gap-2 bg-indigo-500/10 rounded-lg p-2 border border-indigo-500/20">
                  {selectedUser.photoUrl ? (
                    <img src={selectedUser.photoUrl} className="w-7 h-7 rounded-full object-cover" />
                  ) : (
                    <div className="w-7 h-7 rounded-full bg-slate-700 flex items-center justify-center text-[8px] text-slate-400">?</div>
                  )}
                  <div className="flex-1 min-w-0">
                    <div className="text-white text-[10px] font-medium truncate">{selectedUser.name}</div>
                    <div className="text-[8px] text-slate-500 truncate">{selectedUser.uid}</div>
                  </div>
                  <button onClick={() => { setSelectedUser(null); setSearchUser(''); }} className="text-rose-400 hover:text-rose-300"><X className="w-3 h-3" /></button>
                </div>
              )}
              {!selectedUser && searchUser && filteredUsers.length > 0 && (
                <div className="mt-1 bg-[#161618] border border-white/10 rounded-lg max-h-40 overflow-y-auto">
                  {filteredUsers.map(u => (
                    <button
                      key={u.uid}
                      onClick={() => { setSelectedUser(u); setSearchUser(''); }}
                      className="w-full flex items-center gap-2 px-2 py-1.5 text-[10px] text-white hover:bg-white/5 text-left"
                    >
                      {u.photoUrl ? <img src={u.photoUrl} className="w-5 h-5 rounded-full object-cover" /> : <div className="w-5 h-5 rounded-full bg-slate-700" />}
                      <span className="truncate">{u.name}</span>
                      <span className="text-slate-500 ml-auto text-[8px]">{u.uid.slice(0, 8)}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Store item select */}
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Store Item</label>
              <input
                type="text"
                value={storeSearch}
                onChange={e => setStoreSearch(e.target.value)}
                placeholder="Search items..."
                className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
              />
              {selectedItem && (
                <div className="mt-2 flex items-center gap-2 bg-emerald-500/10 rounded-lg p-2 border border-emerald-500/20">
                  {selectedItem.iconAsset ? (
                    <img src={selectedItem.iconAsset} className="w-7 h-7 rounded object-cover" />
                  ) : (
                    <div className="w-7 h-7 rounded bg-slate-700 flex items-center justify-center text-[8px] text-slate-400">?</div>
                  )}
                  <div className="flex-1 min-w-0">
                    <div className="text-white text-[10px] font-medium truncate">{selectedItem.name}</div>
                    <div className="text-[8px] text-slate-500">{selectedItem.category}</div>
                  </div>
                  <button onClick={() => { setSelectedItem(null); setStoreSearch(''); }} className="text-rose-400 hover:text-rose-300"><X className="w-3 h-3" /></button>
                </div>
              )}
              {!selectedItem && (
                <div className="mt-1 bg-[#161618] border border-white/10 rounded-lg max-h-40 overflow-y-auto">
                  {filteredStore.map(item => (
                    <button
                      key={item.itemId}
                      onClick={() => { setSelectedItem(item); setStoreSearch(''); }}
                      className="w-full flex items-center gap-2 px-2 py-1.5 text-[10px] text-white hover:bg-white/5 text-left"
                    >
                      {item.iconAsset ? <img src={item.iconAsset} className="w-5 h-5 rounded object-cover" /> : <div className="w-5 h-5 rounded bg-slate-700" />}
                      <span className="truncate">{item.name}</span>
                      <span className="text-slate-500 ml-auto text-[8px]">{item.category}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Expiry */}
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Expiry (days)</label>
              <input
                type="number"
                min={1}
                max={365}
                value={expiryDays}
                onChange={e => setExpiryDays(Number(e.target.value) || 1)}
                className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
              />
              <p className="text-[8px] text-slate-600 mt-1">Item will be removed after {expiryDays} day{expiryDays > 1 ? 's' : ''}</p>
            </div>
          </div>

          <div className="flex gap-2">
            <button
              onClick={handleSend}
              disabled={!selectedUser || !selectedItem || sending}
              className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-xs text-white font-semibold rounded-lg flex items-center gap-1"
            >
              <Send className="w-3 h-3" /> {sending ? 'Sending...' : 'Send Item'}
            </button>
          </div>
        </div>
      )}

      <DataTable
        loading={loading}
        columns={[
          { key: 'itemName', label: 'Item', render: (g: GiftedItem) => (
            <div className="flex items-center gap-2">
              {g.itemIcon ? <img src={g.itemIcon} className="w-5 h-5 rounded object-cover" /> : <div className="w-5 h-5 rounded bg-slate-700" />}
              <div>
                <div className="text-white text-[10px] font-medium">{g.itemName}</div>
                <div className="text-[8px] text-slate-500">{g.itemCategory}</div>
              </div>
            </div>
          )},
          { key: 'uid', label: 'User ID', render: (g: GiftedItem) => (
            <span className="text-[10px] font-mono text-slate-300" title={g.uid}>{g.uid.slice(0, 12)}...</span>
          )},
          { key: 'sentByName', label: 'Sent By', render: (g: GiftedItem) => (
            <span className="text-[10px] text-slate-400">{g.sentByName}</span>
          )},
          { key: 'sentAt', label: 'Sent', sortable: true, render: (g: GiftedItem) => (
            <span className="text-[10px] text-slate-400">{new Date(g.sentAt).toLocaleDateString()}</span>
          )},
          { key: 'expiresAt', label: 'Expires', sortable: true, render: (g: GiftedItem) => {
            const expired = g.expiresAt < now;
            const soon = !expired && g.expiresAt - now < 86400000;
            return (
              <div className="flex items-center gap-1">
                {expired ? <AlertTriangle className="w-3 h-3 text-rose-400" /> : soon ? <Clock className="w-3 h-3 text-amber-400" /> : <Clock className="w-3 h-3 text-emerald-400" />}
                <span className={`text-[10px] ${expired ? 'text-rose-400' : soon ? 'text-amber-400' : 'text-emerald-400'}`}>
                  {expired ? 'Expired' : `${Math.ceil((g.expiresAt - now) / 86400000)}d`}
                </span>
              </div>
            );
          }},
        ]}
        data={giftedItems}
        searchKeys={['itemName', 'uid', 'itemCategory', 'sentByName']}
        onDelete={handleRevoke}
      />
    </div>
  );
}
