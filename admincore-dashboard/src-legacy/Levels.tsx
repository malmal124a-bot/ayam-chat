import { useEffect, useState } from 'react';
import { LevelConfig, LevelType, BadgeConfig } from '../types';
import { getLevels, updateLevel, getAppConfig, updateAppConfig, getBadges } from '../lib/db';
import { uploadLevelImage } from '../lib/storage';
import DataTable from '../components/DataTable';
import ImageUpload from '../components/ImageUpload';
import { Save, X, Plus, TrendingUp, Zap, Gem } from 'lucide-react';
import { to6Hex } from '../lib/colors';

const LEVEL_TYPES: LevelType[] = [
  { id: 'wealth', name: 'Wealth', icon: '💰', color: 'text-amber-400' },
  { id: 'recharge', name: 'Recharge', icon: '⚡', color: 'text-cyan-400' },
  { id: 'gems', name: 'Gems', icon: '💎', color: 'text-rose-400' },
];

export default function LevelsPage() {
  const [levels, setLevels] = useState<Record<string, LevelConfig[]>>({ wealth: [], recharge: [], gems: [] });
  const [badges, setBadges] = useState<BadgeConfig[]>([]);
  const [activeType, setActiveType] = useState<'wealth' | 'recharge' | 'gems'>('wealth');
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<LevelConfig | null>(null);
  const [coinsPerXp, setCoinsPerXp] = useState(10);
  const [form, setForm] = useState({
    title: '', minExp: 0, maxExp: 0, coins: 0, diamonds: 0, frame: '', badge: '',
    imageUrl: '', frameUrl: '', progressColor: '', boxImageUrl: '',
  });

  const loadAll = async () => {
    const [wealth, recharge, gems, config, badgeList] = await Promise.all([
      getLevels('wealth'), getLevels('recharge'), getLevels('gems'), getAppConfig(), getBadges(),
    ]);
    setLevels({ wealth, recharge, gems });
    setBadges(badgeList);
    if (config?.coinsPerRechargeXp) setCoinsPerXp(config.coinsPerRechargeXp);
    setLoading(false);
  };
  useEffect(() => { loadAll(); }, []);

  const resetForm = () => setForm({ title: '', minExp: 0, maxExp: 0, coins: 0, diamonds: 0, frame: '', badge: '', imageUrl: '', frameUrl: '', progressColor: '', boxImageUrl: '' });

  const handleEdit = (l: LevelConfig) => {
    setEditing(l);
    setForm({
      title: l.title, minExp: l.minExp, maxExp: l.maxExp,
      coins: l.rewards?.coins || 0, diamonds: l.rewards?.diamonds || 0,
      frame: l.rewards?.frame || '', badge: l.rewards?.badge || '',
      imageUrl: l.imageUrl || '', frameUrl: l.frameUrl || '',
      progressColor: l.progressColor || '', boxImageUrl: l.boxImageUrl || '',
    });
  };

  const handleSave = async () => {
    if (!editing) return;
    try {
      const rewards: Record<string, unknown> = {};
      if (form.coins > 0) rewards.coins = form.coins;
      if (form.diamonds > 0) rewards.diamonds = form.diamonds;
      if (form.frame) rewards.frame = form.frame;
      if (form.badge) rewards.badge = form.badge;
      
      // Find the selected badge to get its URL
      const selectedBadge = badges.find(b => b.id === form.badge);
      
      await updateLevel(activeType, editing.level, {
        title: form.title, minExp: form.minExp, maxExp: form.maxExp,
        type: activeType,
        imageUrl: form.imageUrl || null,
        frameUrl: form.frameUrl || null,
        badgeUrl: form.badgeUrl || selectedBadge?.iconAsset || null,
        progressColor: form.progressColor || null,
        boxImageUrl: form.boxImageUrl || null,
        rewards,
      });
      setEditing(null);
      resetForm();
      loadAll();
    } catch (err) {
      alert('فشل الحفظ: ' + (err as Error).message);
    }
  };

  const handleAddNew = async () => {
    try {
      const list = levels[activeType];
      const lastLevel = list.length > 0 ? Math.max(...list.map(l => l.level)) : 0;
      const newLevel = lastLevel + 1;
      await updateLevel(activeType, newLevel, {
        level: newLevel, type: activeType, title: `Level ${newLevel}`,
        minExp: newLevel * 1000, maxExp: (newLevel + 1) * 1000,
        rewards: { coins: newLevel * 100 },
      });
      loadAll();
    } catch (err) {
      alert('فشل الإضافة: ' + (err as Error).message);
    }
  };

  const handleCoinsPerXpSave = async () => {
    await updateAppConfig({ coinsPerRechargeXp: coinsPerXp });
  };

  const typeIcon = (id: string) => {
    const t = LEVEL_TYPES.find(t => t.id === id);
    return t ? `${t.icon} ${t.name}` : id;
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">Level System</h2>
          <p className="text-slate-500 text-xs mt-0.5">
            {levels[activeType].length} levels in {activeType}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={handleAddNew} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
            <Plus className="w-3.5 h-3.5" /> Add Level
          </button>
        </div>
      </div>

      {/* Level Type Tabs */}
      <div className="flex gap-2">
        {LEVEL_TYPES.map(t => (
          <button
            key={t.id}
            onClick={() => { setActiveType(t.id); setEditing(null); }}
            className={`px-4 py-2 rounded-lg text-xs font-semibold transition-all ${
              activeType === t.id
                ? 'bg-indigo-600 text-white'
                : 'bg-[#141417] text-slate-400 hover:text-white'
            }`}
          >
            {t.icon} {t.name}
          </button>
        ))}
      </div>

      {/* Coins Per Recharge XP Config */}
      <div className="bg-[#141417] rounded-2xl border border-cyan-500/20 p-4 flex items-center gap-4">
        <span className="text-xs text-slate-400 font-bold uppercase">Coins per Recharge XP:</span>
        <input
          type="number"
          value={coinsPerXp}
          onChange={e => setCoinsPerXp(Number(e.target.value))}
          className="w-24 bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
        />
        <button onClick={handleCoinsPerXpSave} className="px-3 py-1.5 bg-cyan-600 hover:bg-cyan-700 text-xs text-white font-semibold rounded-lg">
          Save
        </button>
      </div>

      {/* Edit Form */}
      {editing && (
        <div className="bg-[#141417] rounded-2xl border border-indigo-500/20 p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-white font-semibold text-sm">
              {typeIcon(activeType)} - Editing Level {editing.level}
            </h3>
            <button onClick={() => { setEditing(null); resetForm(); }} className="text-slate-400 hover:text-white">
              <X className="w-4 h-4" />
            </button>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Title</label>
              <input type="text" value={form.title} onChange={e => setForm(p => ({ ...p, title: e.target.value }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Min EXP</label>
              <input type="number" value={form.minExp} onChange={e => setForm(p => ({ ...p, minExp: Number(e.target.value) }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Max EXP</label>
              <input type="number" value={form.maxExp} onChange={e => setForm(p => ({ ...p, maxExp: Number(e.target.value) }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-amber-400 font-bold mb-1">Reward Coins</label>
              <input type="number" value={form.coins} onChange={e => setForm(p => ({ ...p, coins: Number(e.target.value) }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-cyan-400 font-bold mb-1">Reward Diamonds</label>
              <input type="number" value={form.diamonds} onChange={e => setForm(p => ({ ...p, diamonds: Number(e.target.value) }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Reward Frame ID</label>
              <input type="text" value={form.frame} onChange={e => setForm(p => ({ ...p, frame: e.target.value }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Reward Badge</label>
              <select
                value={form.badge}
                onChange={e => setForm(p => ({ ...p, badge: e.target.value }))}
                className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
              >
                <option value="">Select Badge</option>
                {badges
                  .filter(b => b.type === 'level' || !b.type) // Show all level badges OR untyped
                  .map(b => (
                    <option key={b.id} value={b.id}>
                      {b.name}
                      {b.levelType && b.levelNumber ? ` (${b.levelType} Lv. ${b.levelNumber})` : ''}
                    </option>
                  ))}
              </select>
            </div>
            <div>
              <label className="block text-[10px] uppercase text-amber-400 font-bold mb-1">Progress Bar Color</label>
              <div className="flex gap-2 items-center">
                <input type="color" value={to6Hex(form.progressColor || '#DE880F')} onChange={e => setForm(p => ({ ...p, progressColor: e.target.value }))} className="w-10 h-8 rounded border border-white/10 bg-transparent cursor-pointer" />
                <input type="text" value={form.progressColor} onChange={e => setForm(p => ({ ...p, progressColor: e.target.value }))} className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white font-mono" placeholder="#DE880F" />
              </div>
            </div>
          </div>
          <div className="grid grid-cols-4 gap-4">
            <ImageUpload
              currentUrl={form.imageUrl}
              onUpload={file => uploadLevelImage(file, activeType, editing.level)}
              onUrlChange={url => setForm(p => ({ ...p, imageUrl: url }))}
              label="Level Image"
            />
            <ImageUpload
              currentUrl={form.frameUrl}
              onUpload={file => uploadLevelImage(file, `${activeType}_frame`, editing.level)}
              onUrlChange={url => setForm(p => ({ ...p, frameUrl: url }))}
              label="Frame (SVGA)"
              accept=".svga,.webp,.png,.mp4,.vap"
            />
            <ImageUpload
              currentUrl={form.badgeUrl || (form.badge ? badges.find(b => b.id === form.badge)?.iconAsset : '')}
              onUpload={file => uploadLevelImage(file, `${activeType}_badge`, editing.level)}
              onUrlChange={url => setForm(p => ({ ...p, badgeUrl: url }))}
              label="Badge Image"
              accept=".webp,.png"
            />
            <ImageUpload
              currentUrl={form.boxImageUrl}
              onUpload={file => uploadLevelImage(file, `${activeType}_box`, editing.level)}
              onUrlChange={url => setForm(p => ({ ...p, boxImageUrl: url }))}
              label="Box Background"
              accept=".webp,.png,.jpg"
            />
          </div>
          <div className="flex gap-2">
            <button onClick={handleSave} className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
              <Save className="w-3 h-3" /> Save
            </button>
            <button onClick={() => { setEditing(null); resetForm(); }} className="px-4 py-1.5 border border-white/10 text-xs text-slate-400 rounded-lg">Cancel</button>
          </div>
        </div>
      )}

      {/* Levels Table */}
      <DataTable
        loading={loading}
        columns={[
          { key: 'level', label: 'Level', sortable: true, width: '60px' },
          {
            key: 'imageUrl', label: 'Image', width: '60px',
            render: (l: LevelConfig) => l.imageUrl
              ? <img src={l.imageUrl} className="w-8 h-8 object-contain rounded" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
              : <div className="w-8 h-8 rounded bg-slate-800 flex items-center justify-center text-xs text-slate-600">-</div>,
          },
          { key: 'title', label: 'Title', sortable: true },
          { key: 'minExp', label: 'Min EXP', sortable: true },
          { key: 'maxExp', label: 'Max EXP', sortable: true },
          {
            key: 'rewards', label: 'Rewards',
            render: (l: LevelConfig) => {
              const r = l.rewards;
              if (!r) return '-';
              const parts: string[] = [];
              if (r.coins) parts.push(`${r.coins} coins`);
              if (r.diamonds) parts.push(`${r.diamonds} dia`);
              if (r.frame) parts.push(`frame`);
              if (r.badge) parts.push(`badge`);
              return parts.length ? parts.join(', ') : '-';
            },
          },
          {
            key: 'frameUrl', label: 'Frame', width: '60px',
            render: (l: LevelConfig) => l.frameUrl
              ? <img src={l.frameUrl} className="w-8 h-8 object-contain rounded" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
              : '-',
          },
          {
            key: 'badgeUrl', label: 'Badge', width: '60px',
            render: (l: LevelConfig) => l.badgeUrl
              ? <img src={l.badgeUrl} className="w-8 h-8 object-contain rounded" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
              : '-',
          },
        ]}
        data={levels[activeType]}
        onEdit={handleEdit}
        searchKeys={['title']}
      />
    </div>
  );
}
