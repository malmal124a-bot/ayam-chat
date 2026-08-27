import { useEffect, useState } from 'react';
import { VIPConfig, VIPBenefitItem, VIPAdditionalFile } from '../types';
import { getVIPConfig, updateVIPConfig } from '../lib/db';
import { uploadStoreItem } from '../lib/storage';
import { Crown, Plus, Save, X, Trash2, FolderOpen } from 'lucide-react';
import ImageUpload from '../components/ImageUpload';

const emptyItem = (): VIPBenefitItem => ({ name: '', img: '', peculiarityId: 0, title: '' });
const emptyFile = (): VIPAdditionalFile => ({ name: '', url: '', type: '' });

export default function VIPPage() {
  const [configs, setConfigs] = useState<VIPConfig[]>([]);
  const [editing, setEditing] = useState<VIPConfig | null>(null);
  const [form, setForm] = useState({
    name: '', minSpend: 0, price: 0, color: '#DE880F',
    imageUrl: '', bgUrl: '', logoUrl: '',
    medalUrl: '', medalImgUrl: '', medalName: '',
    headwearUrl: '', headwearImgUrl: '', headwearName: '', headwearKey: '', headwearCardBg: '',
    entranceUrl: '', entranceImgUrl: '', entranceName: '', entranceKey: '', entranceCardBg: '',
    bubbleUrl: '', bubbleImgUrl: '', bubbleName: '', bubbleKey: '', bubbleCardBg: '',
    necklaceUrl: '', necklaceImgUrl: '', necklaceName: '', necklaceKey: '', necklaceCardBg: '',
    carUrl: '', carImgUrl: '', carName: '', carKey: '', carCardBg: '',
    coverUrl: '', coverImgUrl: '', coverName: '', coverKey: '', coverCardBg: '',
    buyBtnImgUrl: '', coinImgUrl: '', purchaseBarBg: '',
    cardBgUrl: '',
    cardRadius: 16,
  });
  const [items, setItems] = useState<VIPBenefitItem[]>([]);
  const [additionalFiles, setAdditionalFiles] = useState<VIPAdditionalFile[]>([]);

  useEffect(() => { getVIPConfig().then(setConfigs); }, []);

  const handleEdit = (v: VIPConfig) => {
    setEditing(v);
    setForm({
      name: v.name, minSpend: v.minSpend, price: v.price || 0,
      color: v.color || '#DE880F',
      imageUrl: v.imageUrl || '', bgUrl: v.bgUrl || '',
      logoUrl: v.logoUrl || '', cardRadius: v.cardRadius || 16,
      medalUrl: v.medalUrl || '', medalImgUrl: v.medalImgUrl || '', medalName: v.medalName || '',
      headwearUrl: v.headwearUrl || '', headwearImgUrl: v.headwearImgUrl || '', headwearName: v.headwearName || '', headwearKey: v.headwearKey || '', headwearCardBg: v.headwearCardBg || '',
      entranceUrl: v.entranceUrl || '', entranceImgUrl: v.entranceImgUrl || '', entranceName: v.entranceName || '', entranceKey: v.entranceKey || '', entranceCardBg: v.entranceCardBg || '',
      bubbleUrl: v.bubbleUrl || '', bubbleImgUrl: v.bubbleImgUrl || '', bubbleName: v.bubbleName || '', bubbleKey: v.bubbleKey || '', bubbleCardBg: v.bubbleCardBg || '',
      necklaceUrl: v.necklaceUrl || '', necklaceImgUrl: v.necklaceImgUrl || '', necklaceName: v.necklaceName || '', necklaceKey: v.necklaceKey || '', necklaceCardBg: v.necklaceCardBg || '',
      carUrl: v.carUrl || '', carImgUrl: v.carImgUrl || '', carName: v.carName || '', carKey: v.carKey || '', carCardBg: v.carCardBg || '',
      coverUrl: v.coverUrl || '', coverImgUrl: v.coverImgUrl || '', coverName: v.coverName || '', coverKey: v.coverKey || '', coverCardBg: v.coverCardBg || '',
      buyBtnImgUrl: v.buyBtnImgUrl || '', coinImgUrl: v.coinImgUrl || '', purchaseBarBg: v.purchaseBarBg || '',
      cardBgUrl: v.cardBgUrl || '',
    });
    setItems(v.items?.length ? v.items : v.benefits.map(b => ({ name: b, img: '', peculiarityId: 0, title: '' })));
    setAdditionalFiles(v.additionalFiles || []);
  };

  const handleSave = async () => {
    if (!editing) return;
    const benefits = items.map(i => i.name).filter(Boolean);
    await updateVIPConfig(editing.tier, { ...form, benefits });
    setEditing(null);
    setConfigs(await getVIPConfig());
  };

  const handleAdd = async () => {
    const lastTier = configs.length > 0 ? Math.max(...configs.map(c => c.tier)) : 0;
    const newTier = lastTier + 1;
    await updateVIPConfig(newTier, {
      tier: newTier, name: `VIP ${newTier}`, minSpend: newTier * 1000, color: '#DE880F',
      benefits: [`Access to VIP ${newTier} features`],
    });
    setConfigs(await getVIPConfig());
  };

  const updateItem = (idx: number, field: keyof VIPBenefitItem, value: string) => {
    setItems(prev => prev.map((item, i) => i === idx ? { ...item, [field]: value } : item));
  };

  const addItem = () => setItems(prev => [...prev, emptyItem()]);
  const removeItem = (idx: number) => setItems(prev => prev.filter((_, i) => i !== idx));
  const addFile = () => setAdditionalFiles(prev => [...prev, emptyFile()]);
  const removeFile = (idx: number) => setAdditionalFiles(prev => prev.filter((_, i) => i !== idx));
  const updateFile = (idx: number, field: keyof VIPAdditionalFile, value: string) => {
    setAdditionalFiles(prev => prev.map((f, i) => i === idx ? { ...f, [field]: value } : f));
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">VIP Configuration</h2>
          <p className="text-slate-500 text-xs mt-0.5">{configs.length} VIP tiers</p>
        </div>
        <button onClick={handleAdd} className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
          <Plus className="w-3.5 h-3.5" /> Add Tier
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {configs.map(v => (
          <div key={v.tier} className="bg-[#141417] rounded-2xl border border-white/5 p-5 hover:border-white/10 transition-colors cursor-pointer" onClick={() => handleEdit(v)}>
            <div className="flex items-center gap-2 mb-3">
              {v.color && !v.color.startsWith('#') ? <img src={v.color} className="w-5 h-5 object-contain" /> : <Crown className="w-5 h-5" style={{ color: v.color || '#DE880F' }} />}
              <h3 className="text-white font-semibold text-sm">VIP {v.tier}</h3>
            </div>
            {v.imageUrl && (
              <img src={v.imageUrl} alt={v.name} className="w-full h-28 object-contain rounded-lg mb-2 bg-black/30" />
            )}
            <div className="text-lg font-bold font-mono" style={{ color: (v.color && !v.color.startsWith('#')) ? '#DE880F' : (v.color || '#DE880F') }}>{v.name}</div>
            <div className="text-[10px] text-slate-500 mt-1">Min spend: ${v.minSpend.toLocaleString()}</div>
            <ul className="mt-2 space-y-1">
              {v.benefits?.map((b, i) => <li key={i} className="text-[10px] text-slate-400 flex items-start gap-1"><span className="text-emerald-400 mt-0.5">•</span>{b}</li>)}
            </ul>
          </div>
        ))}
      </div>

      {editing && (
        <div className="bg-[#141417] rounded-2xl border border-indigo-500/20 p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-white font-semibold text-sm">Edit VIP {editing.tier}</h3>
            <button onClick={() => setEditing(null)} className="text-slate-400 hover:text-white"><X className="w-4 h-4" /></button>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Name</label>
              <input type="text" value={form.name} onChange={e => setForm(p => ({ ...p, name: e.target.value }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Min Spend ($)</label>
              <input type="number" value={form.minSpend} onChange={e => setForm(p => ({ ...p, minSpend: Number(e.target.value) }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Color Image</label>
              <ImageUpload
                currentUrl={form.color.startsWith('#') ? '' : form.color}
                onUpload={(file) => uploadStoreItem(file, `vip_color_${editing.tier}`)}
                onUrlChange={(url) => setForm(p => ({ ...p, color: url }))}
                label="Color Image"
                accept="image/*"
              />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Price ($)</label>
              <input type="number" value={form.price} onChange={e => setForm(p => ({ ...p, price: Number(e.target.value) }))} className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
            </div>
            <div>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">Card Radius ({form.cardRadius}px)</label>
              <input type="range" min="0" max="30" value={form.cardRadius} onChange={e => setForm(p => ({ ...p, cardRadius: Number(e.target.value) }))} className="w-full accent-indigo-500" />
            </div>
            <ImageUpload
              currentUrl={form.cardBgUrl}
              onUpload={(file) => uploadStoreItem(file, `vip_card_bg_${editing.tier}`)}
              onUrlChange={(url) => setForm(p => ({ ...p, cardBgUrl: url }))}
              label="Accessory Card BG (خلفية مربع الملحق)"
              accept="image/*"
            />
          </div>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            <ImageUpload
              currentUrl={form.imageUrl}
              onUpload={(file) => uploadStoreItem(file, `vip_img_${editing.tier}`)}
              onUrlChange={(url) => setForm(p => ({ ...p, imageUrl: url }))}
              label="VIP Name Image (صورة اسم VIP)"
              accept="image/*,.svga,.zip,.mp4,.vap"
            />
            <ImageUpload
              currentUrl={form.bgUrl}
              onUpload={(file) => uploadStoreItem(file, `vip_bg_${editing.tier}`)}
              onUrlChange={(url) => setForm(p => ({ ...p, bgUrl: url }))}
              label="Background (الغلاف)"
              accept="image/*,.svga,.zip,.mp4,.vap"
            />
            <ImageUpload
              currentUrl={form.logoUrl}
              onUpload={(file) => uploadStoreItem(file, `vip_logo_${editing.tier}`)}
              onUrlChange={(url) => setForm(p => ({ ...p, logoUrl: url }))}
              label="Logo"
              accept="image/*,.svga,.zip,.mp4,.vap"
            />
          </div>

          <div className="border-t border-white/5 pt-4">
            <h4 className="text-[10px] uppercase text-slate-400 font-bold mb-3">VIP Items — Image + Model (صورة + موديل)</h4>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            <div className="col-span-2 md:col-span-3">
              <div className="grid grid-cols-4 gap-2">
                <div><label className="block text-[10px] text-slate-400 mb-1">Name</label><input type="text" value={form.medalName} onChange={e => setForm(p => ({ ...p, medalName: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="Medal Name" /></div>
                <ImageUpload currentUrl={form.medalImgUrl} onUpload={(file) => uploadStoreItem(file, `vip_medal_img_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, medalImgUrl: url }))} label="Image" accept="image/*" />
                <ImageUpload currentUrl={form.medalUrl} onUpload={(file) => uploadStoreItem(file, `vip_medal_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, medalUrl: url }))} label="SVGA" accept="image/*,.svga,.zip,.mp4,.vap" />
              </div>
            </div>
            <div className="col-span-2 md:col-span-3">
              <div className="grid grid-cols-4 gap-2">
                <div>
                  <label className="block text-[10px] text-slate-400 mb-1">Name</label>
                  <input type="text" value={form.headwearName} onChange={e => setForm(p => ({ ...p, headwearName: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="Frame Name" />
                </div>
                <div>
                  <label className="block text-[10px] text-slate-400 mb-1">Key</label>
                  <input type="text" value={form.headwearKey} onChange={e => setForm(p => ({ ...p, headwearKey: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="active_frame" />
                </div>
                <ImageUpload currentUrl={form.headwearCardBg} onUpload={(file) => uploadStoreItem(file, `vip_headwear_card_bg_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, headwearCardBg: url }))} label="Card BG" accept="image/*" />
                <ImageUpload currentUrl={form.headwearImgUrl} onUpload={(file) => uploadStoreItem(file, `vip_headwear_img_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, headwearImgUrl: url }))} label="Image" accept="image/*" />
              </div>
              <div className="mt-2">
                <ImageUpload currentUrl={form.headwearUrl} onUpload={(file) => uploadStoreItem(file, `vip_headwear_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, headwearUrl: url }))} label="Frame SVGA" accept="image/*,.svga,.zip,.mp4,.vap" />
              </div>
            </div>
            <div className="col-span-2 md:col-span-3">
              <div className="grid grid-cols-4 gap-2">
                <div><label className="block text-[10px] text-slate-400 mb-1">Name</label><input type="text" value={form.entranceName} onChange={e => setForm(p => ({ ...p, entranceName: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="Entrance Name" /></div>
                <div><label className="block text-[10px] text-slate-400 mb-1">Key</label><input type="text" value={form.entranceKey} onChange={e => setForm(p => ({ ...p, entranceKey: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="active_entrance" /></div>
                <ImageUpload currentUrl={form.entranceCardBg} onUpload={(file) => uploadStoreItem(file, `vip_entrance_card_bg_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, entranceCardBg: url }))} label="Card BG" accept="image/*" />
                <ImageUpload currentUrl={form.entranceImgUrl} onUpload={(file) => uploadStoreItem(file, `vip_entrance_img_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, entranceImgUrl: url }))} label="Image" accept="image/*" />
              </div>
              <div className="mt-2"><ImageUpload currentUrl={form.entranceUrl} onUpload={(file) => uploadStoreItem(file, `vip_entrance_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, entranceUrl: url }))} label="Entrance SVGA" accept="image/*,.svga,.zip,.mp4,.vap" /></div>
            </div>
            <div className="col-span-2 md:col-span-3">
              <div className="grid grid-cols-4 gap-2">
                <div><label className="block text-[10px] text-slate-400 mb-1">Name</label><input type="text" value={form.bubbleName} onChange={e => setForm(p => ({ ...p, bubbleName: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="Bubble Name" /></div>
                <div><label className="block text-[10px] text-slate-400 mb-1">Key</label><input type="text" value={form.bubbleKey} onChange={e => setForm(p => ({ ...p, bubbleKey: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="active_bubble" /></div>
                <ImageUpload currentUrl={form.bubbleCardBg} onUpload={(file) => uploadStoreItem(file, `vip_bubble_card_bg_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, bubbleCardBg: url }))} label="Card BG" accept="image/*" />
                <ImageUpload currentUrl={form.bubbleImgUrl} onUpload={(file) => uploadStoreItem(file, `vip_bubble_img_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, bubbleImgUrl: url }))} label="Image" accept="image/*" />
              </div>
              <div className="mt-2"><ImageUpload currentUrl={form.bubbleUrl} onUpload={(file) => uploadStoreItem(file, `vip_bubble_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, bubbleUrl: url }))} label="Bubble SVGA" accept="image/*,.svga,.zip,.mp4,.vap" /></div>
            </div>
            <div className="col-span-2 md:col-span-3">
              <div className="grid grid-cols-4 gap-2">
                <div><label className="block text-[10px] text-slate-400 mb-1">Name</label><input type="text" value={form.necklaceName} onChange={e => setForm(p => ({ ...p, necklaceName: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="Necklace Name" /></div>
                <div><label className="block text-[10px] text-slate-400 mb-1">Key</label><input type="text" value={form.necklaceKey} onChange={e => setForm(p => ({ ...p, necklaceKey: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="active_necklace" /></div>
                <ImageUpload currentUrl={form.necklaceCardBg} onUpload={(file) => uploadStoreItem(file, `vip_necklace_card_bg_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, necklaceCardBg: url }))} label="Card BG" accept="image/*" />
                <ImageUpload currentUrl={form.necklaceImgUrl} onUpload={(file) => uploadStoreItem(file, `vip_necklace_img_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, necklaceImgUrl: url }))} label="Image" accept="image/*" />
              </div>
              <div className="mt-2"><ImageUpload currentUrl={form.necklaceUrl} onUpload={(file) => uploadStoreItem(file, `vip_necklace_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, necklaceUrl: url }))} label="Necklace SVGA" accept="image/*,.svga,.zip,.mp4,.vap" /></div>
            </div>
            <div className="col-span-2 md:col-span-3">
              <div className="grid grid-cols-4 gap-2">
                <div><label className="block text-[10px] text-slate-400 mb-1">Name</label><input type="text" value={form.carName} onChange={e => setForm(p => ({ ...p, carName: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="Car Name" /></div>
                <div><label className="block text-[10px] text-slate-400 mb-1">Key</label><input type="text" value={form.carKey} onChange={e => setForm(p => ({ ...p, carKey: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="active_car" /></div>
                <ImageUpload currentUrl={form.carCardBg} onUpload={(file) => uploadStoreItem(file, `vip_car_card_bg_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, carCardBg: url }))} label="Card BG" accept="image/*" />
                <ImageUpload currentUrl={form.carImgUrl} onUpload={(file) => uploadStoreItem(file, `vip_car_img_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, carImgUrl: url }))} label="Image" accept="image/*" />
              </div>
              <div className="mt-2"><ImageUpload currentUrl={form.carUrl} onUpload={(file) => uploadStoreItem(file, `vip_car_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, carUrl: url }))} label="Car SVGA" accept="image/*,.svga,.zip,.mp4,.vap" /></div>
            </div>
            <div className="col-span-2 md:col-span-3">
              <div className="grid grid-cols-4 gap-2">
                <div><label className="block text-[10px] text-slate-400 mb-1">Name</label><input type="text" value={form.coverName} onChange={e => setForm(p => ({ ...p, coverName: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="Cover Name" /></div>
                <div><label className="block text-[10px] text-slate-400 mb-1">Key</label><input type="text" value={form.coverKey} onChange={e => setForm(p => ({ ...p, coverKey: e.target.value }))} className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" placeholder="active_cover" /></div>
                <ImageUpload currentUrl={form.coverCardBg} onUpload={(file) => uploadStoreItem(file, `vip_cover_card_bg_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, coverCardBg: url }))} label="Card BG" accept="image/*" />
                <ImageUpload currentUrl={form.coverImgUrl} onUpload={(file) => uploadStoreItem(file, `vip_cover_img_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, coverImgUrl: url }))} label="Image" accept="image/*" />
              </div>
              <div className="mt-2"><ImageUpload currentUrl={form.coverUrl} onUpload={(file) => uploadStoreItem(file, `vip_cover_${editing.tier}`)} onUrlChange={(url) => setForm(p => ({ ...p, coverUrl: url }))} label="Cover SVGA" accept="image/*,.svga,.zip,.mp4,.vap" /></div>
            </div>
            </div>
          </div>

          {/* Benefit Items with Images */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="block text-[10px] uppercase text-slate-400 font-bold">Benefits / Features (المميزات)</label>
              <button onClick={addItem} className="px-2 py-1 bg-indigo-600 hover:bg-indigo-700 text-[10px] text-white font-semibold rounded flex items-center gap-1">
                <Plus className="w-3 h-3" /> Add
              </button>
            </div>
            <div className="space-y-3">
              {items.map((item, idx) => (
                <div key={idx} className="bg-[#161618] rounded-xl border border-white/5 p-3">
                  <div className="flex items-start justify-between mb-2">
                    <span className="text-[10px] text-slate-500 font-semibold">Item #{idx + 1}</span>
                    <button onClick={() => removeItem(idx)} className="text-rose-400 hover:text-rose-300">
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
                    <div>
                      <label className="block text-[10px] text-slate-400 mb-1">Benefit Name</label>
                      <input
                        type="text"
                        value={item.name}
                        onChange={e => updateItem(idx, 'name', e.target.value)}
                        className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
                        placeholder="e.g. Exclusive VIP Badge"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] text-slate-400 mb-1">Key (e.g. active_frame)</label>
                      <input
                        type="text"
                        value={item.key || ''}
                        onChange={e => updateItem(idx, 'key', e.target.value)}
                        className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
                        placeholder="active_frame / owned_items"
                      />
                    </div>
                    <ImageUpload
                      currentUrl={item.img}
                      onUpload={(file) => uploadStoreItem(file, `vip_benefit_img_${editing.tier}_${idx}`)}
                      onUrlChange={(url) => updateItem(idx, 'img', url)}
                      label={`Benefit Image ${idx + 1}`}
                      accept="image/*"
                    />
                    <ImageUpload
                      currentUrl={item.svgaUrl}
                      onUpload={(file) => uploadStoreItem(file, `vip_benefit_svga_${editing.tier}_${idx}`)}
                      onUrlChange={(url) => updateItem(idx, 'svgaUrl', url)}
                      label={`Benefit SVGA ${idx + 1}`}
                      accept="image/*,.svga,.zip,.mp4,.vap"
                    />
                  </div>
                </div>
              ))}
              {items.length === 0 && (
                <p className="text-[10px] text-slate-600 text-center py-4">No benefits added yet. Click "Add" to add one.</p>
              )}
            </div>
          </div>

          {/* Additional Files */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="block text-[10px] uppercase text-slate-400 font-bold flex items-center gap-1"><FolderOpen className="w-3 h-3" /> Additional Files (ملفات إضافية)</label>
              <button onClick={addFile} className="px-2 py-1 bg-indigo-600 hover:bg-indigo-700 text-[10px] text-white font-semibold rounded flex items-center gap-1">
                <Plus className="w-3 h-3" /> Add
              </button>
            </div>
            <div className="space-y-3">
              {additionalFiles.map((file, idx) => (
                <div key={idx} className="bg-[#161618] rounded-xl border border-white/5 p-3">
                  <div className="flex items-start justify-between mb-2">
                    <span className="text-[10px] text-slate-500 font-semibold">File #{idx + 1}</span>
                    <button onClick={() => removeFile(idx)} className="text-rose-400 hover:text-rose-300">
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
                    <div>
                      <label className="block text-[10px] text-slate-400 mb-1">Name</label>
                      <input
                        type="text"
                        value={file.name}
                        onChange={e => updateFile(idx, 'name', e.target.value)}
                        className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
                        placeholder="e.g. Wings, Halo"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] text-slate-400 mb-1">Key (e.g. active_frame)</label>
                      <input
                        type="text"
                        value={file.key || ''}
                        onChange={e => updateFile(idx, 'key', e.target.value)}
                        className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
                        placeholder="active_frame / owned_items"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] text-slate-400 mb-1">Type (نوع الملف)</label>
                      <select
                        value={file.type}
                        onChange={e => updateFile(idx, 'type', e.target.value)}
                        className="w-full bg-[#141417] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
                      >
                        <option value="">-- Select --</option>
                        <option value="webp">WEBP</option>
                        <option value="png">PNG</option>
                        <option value="gif">GIF</option>
                        <option value="svga">SVGA</option>
                        <option value="vap">VAP</option>
                        <option value="mp4">MP4</option>
                        <option value="zip">ZIP</option>
                      </select>
                    </div>
                    <ImageUpload
                      currentUrl={file.url}
                      onUpload={(f) => uploadStoreItem(f, `vip_extra_${editing.tier}_${idx}`)}
                      onUrlChange={(url) => updateFile(idx, 'url', url)}
                      label={`File ${idx + 1}`}
                      accept="image/*,.svga,.zip,.mp4,.vap"
                    />
                  </div>
                </div>
              ))}
              {additionalFiles.length === 0 && (
                <p className="text-[10px] text-slate-600 text-center py-4">No additional files added yet.</p>
              )}
            </div>
          </div>

          {/* Purchase Bar Customization */}
          <div>
            <label className="block text-[10px] uppercase text-slate-400 font-bold mb-2">Purchase Bar Customization (تخصيص شريط الشراء)</label>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
              <ImageUpload
                currentUrl={form.buyBtnImgUrl}
                onUpload={(file) => uploadStoreItem(file, `vip_buy_btn_${editing.tier}`)}
                onUrlChange={(url) => setForm(p => ({ ...p, buyBtnImgUrl: url }))}
                label="Buy Button Image"
                accept="image/*"
              />
              <ImageUpload
                currentUrl={form.coinImgUrl}
                onUpload={(file) => uploadStoreItem(file, `vip_coin_${editing.tier}`)}
                onUrlChange={(url) => setForm(p => ({ ...p, coinImgUrl: url }))}
                label="Coin Icon Image"
                accept="image/*"
              />
              <div>
                <label className="block text-[10px] text-slate-400 mb-1">Bar Background Image</label>
                <ImageUpload
                  currentUrl={form.purchaseBarBg.startsWith('#') ? '' : form.purchaseBarBg}
                  onUpload={(file) => uploadStoreItem(file, `vip_purchase_bar_bg_${editing.tier}`)}
                  onUrlChange={(url) => setForm(p => ({ ...p, purchaseBarBg: url }))}
                  label="Bar BG"
                  accept="image/*"
                />
              </div>
            </div>
          </div>

          <div className="flex gap-2">
            <button onClick={handleSave} className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1"><Save className="w-3 h-3" /> Save</button>
            <button onClick={() => setEditing(null)} className="px-4 py-1.5 border border-white/10 text-xs text-slate-400 rounded-lg">Cancel</button>
          </div>
        </div>
      )}
    </div>
  );
}
