import { useEffect, useState, useRef } from 'react';
import { AppConfig, AppAssetRecord } from '../types';
import { getAppConfig, updateAppConfig, upsertAppAsset, getAppAssets } from '../lib/db';
import { uploadToCloudinary, uploadAppAsset } from '../lib/storage';
import { Save, Palette, RotateCcw, Image, Type, Layers, MessageSquare, Trophy, Upload, Camera, Check, FileVideo, FileImage } from 'lucide-react';
import { to6Hex } from '../lib/colors';

const defaultColors = {
  primaryBg: '#FFFFFF',
  textPrimary: '#16151A',
  splashNameColor: '#16151A',
  textSecondary: '#9BA1B6',
  goldColor: '#DE880F',
  buttonColor: '#6366F1',
  buttonTextColor: '#FFFFFF',
  headerColor: '#FFFFFF',
  tabBarColor: '#FFFFFF',
  vipCardBgColor: '#1A3D1A',
  vipCardBorderColor: '#C9A84C',
};

const colorLabels: Record<string, string> = {
  primaryBg: 'خلفية التطبيق (Background)',
  textPrimary: 'النص الرئيسي (Primary Text)',
  splashNameColor: 'لون اسم التطبيق (Splash Name)',
  textSecondary: 'النص الثانوي (Secondary Text)',
  goldColor: 'الذهبي / التمييز (Gold)',
  buttonColor: 'لون الأزرار (Button)',
  buttonTextColor: 'نص الأزرار (Button Text)',
  headerColor: 'خلفية الرأس (Header)',
  tabBarColor: 'خلفية التبويب (Tab Bar)',
  vipCardBgColor: 'خلفية بطاقة VIP',
  vipCardBorderColor: 'حدود بطاقة VIP',
};

const defaultRoomGradients: Record<string, [string, string]> = {
  themeFriend: ['#E447E7', '#A136FF'],
  themeChat: ['#24D5C3', '#03DF99'],
  themeMusic: ['#3697FF', '#B534FF'],
  themeGame: ['#DB9C16', '#F0C724'],
  themeParty: ['#3590FF', '#294BF7'],
  themeHobby: ['#26C889', '#86BC1B'],
};

const gradientLabels: Record<string, string> = {
  themeFriend: 'تدرج الصداقة (Friend)',
  themeChat: 'تدرج الشات (Chat)',
  themeMusic: 'تدرج الموسيقى (Music)',
  themeGame: 'تدرج اللعبة (Game)',
  themeParty: 'تدرج الحفلة (Party)',
  themeHobby: 'تدرج الهواية (Hobby)',
};

const defaultChatColors = {
  bubbleSelf: '#33FFC525',
  bubbleOther: '#1AFFFFFF',
  bubbleSelfBorder: '#33FFC525',
  bubbleOtherBorder: '#1AFFFFFF',
  bubbleSelfText: '#FFC525',
  bubbleOtherText: '#FFFFFF',
};

const chatColorLabels: Record<string, string> = {
  bubbleSelf: 'فقاعة النفس (Self Bubble)',
  bubbleOther: 'فقاعة الآخر (Other Bubble)',
  bubbleSelfBorder: 'حدود النفس (Self Border)',
  bubbleOtherBorder: 'حدود الآخر (Other Border)',
  bubbleSelfText: 'نص النفس (Self Text)',
  bubbleOtherText: 'نص الآخر (Other Text)',
};

const rankCategories = ['wealth', 'charm', 'room'] as const;
const rankCategoryLabels: Record<string, string> = {
  wealth: '💰 الثروة (Wealth)',
  charm: '💎 الجاذبية (Charm)',
  room: '🏠 الغرفة (Room)',
};
const rankCategoryColors: Record<string, Record<string, string>> = {
  wealth: { label: 'الثروة', icon: '💰' },
  charm: { label: 'الجاذبية', icon: '💎' },
  room: { label: 'الغرفة', icon: '🏠' },
};
const rankColorFieldLabels: Record<string, string> = {
  goldColor: 'الذهبية (Gold)',
  silverColor: 'الفضية (Silver)',
  bronzeColor: 'البرونزية (Bronze)',
  pointsColor: 'النقاط (Points)',
  textColor: 'النص (Text)',
  subTextColor: 'النص الثانوي (Sub Text)',
};

function buildDefaultRankConfig(): Record<string, string> {
  const defs: Record<string, string> = {
    trophyIcon: 'emoji_events',
    emptyText: 'No rankings yet',
    goldColor: '#FFD700',
    silverColor: '#C0C0C0',
    bronzeColor: '#CD7F32',
    pointsColor: '#FFD700',
    textColor: '#FFFFFF',
    subTextColor: '#FFFFFF99',
  };
  for (const cat of rankCategories) {
    defs[`${cat}_bg`] = '';
    defs[`${cat}_goldColor`] = '#FFD700';
    defs[`${cat}_silverColor`] = '#C0C0C0';
    defs[`${cat}_bronzeColor`] = '#CD7F32';
    defs[`${cat}_pointsColor`] = '#FFD700';
    defs[`${cat}_textColor`] = '#FFFFFF';
    defs[`${cat}_subTextColor`] = '#FFFFFF99';
    defs[`${cat}_goldFrameKey`] = '';
    defs[`${cat}_silverFrameKey`] = '';
    defs[`${cat}_bronzeFrameKey`] = '';
    defs[`${cat}_bgAssetKey`] = '';
  }
  return defs;
}
const defaultRankConfig = buildDefaultRankConfig();

const screenLabels: Record<string, string> = {
  home: 'الرئيسية (Home)',
  rooms: 'الغرف (Rooms)',
  store: 'المتجر (Store)',
  profile: 'حسابي (Profile)',
  gifts: 'الهدايا (Gifts)',
  ranking: 'الترتيب (Ranking)',
  unions: 'النقابات (Unions)',
  vip: 'العضويات (VIP)',
  settings: 'الإعدادات (Settings)',
  chat: 'الشات (Chat)',
};

function RankAssetUpload({ assetKey, label, accept = 'image/*,.svga,.mp4,.gif,.vap,.json', config, updateField }: {
  assetKey: string; label: string; accept?: string;
  config: AppConfig; updateField: (field: string, value: unknown) => void;
}) {
  const [uploading, setUploading] = useState(false);
  const rc = config.rankConfig || {};
  const currentKey = rc[assetKey as keyof typeof rc] as string || '';
  return (
    <div className="border-t border-white/5 pt-2 mt-2">
      <label className="block text-[9px] text-slate-400 font-bold mb-1">{label}</label>
      <div className="flex gap-2 items-center">
        {currentKey ? (
          <span className="text-[8px] text-emerald-400 font-mono truncate flex-1">{currentKey}</span>
        ) : (
          <span className="text-[8px] text-slate-600 flex-1">لا يوجد</span>
        )}
        <label className="flex items-center gap-1 text-[8px] px-2 py-1 rounded border border-white/10 hover:bg-white/5 cursor-pointer shrink-0">
          <Upload className="w-2 h-2" />
          {uploading ? 'جاري...' : 'رفع'}
          <input type="file" accept={accept} disabled={uploading} className="hidden" onChange={async e => {
            const file = e.target.files?.[0]; if (!file) return;
            setUploading(true);
            try {
              const url = await uploadAppAsset(file, `rank_${assetKey}`);
              const record: AppAssetRecord = {
                id: crypto.randomUUID(), key: `rank_${assetKey}`, name: label,
                type: file.name.endsWith('.svga') ? 'svga' : file.name.endsWith('.vap') ? 'vap' : file.name.endsWith('.json') ? 'lottie' : 'image',
                category: 'الترتيب', subcategory: 'إطارات الترتيب', localPath: '', remoteUrl: url,
                defaultValue: '', mimeType: file.type || 'application/octet-stream', fileSize: file.size,
                width: null, height: null, sortOrder: 0, isActive: true,
                createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
              };
              await upsertAppAsset(record);
              updateField('rankConfig', { ...rc, [assetKey]: `rank_${assetKey}` });
            } catch (err) { alert('فشل الرفع: ' + (err as Error).message); }
            setUploading(false);
          }} />
        </label>
        {currentKey && (
          <button onClick={() => updateField('rankConfig', { ...rc, [assetKey]: '' })}
            className="text-[8px] px-2 py-1 rounded border border-rose-500/20 text-rose-400 hover:bg-rose-500/10 shrink-0">مسح</button>
        )}
      </div>
    </div>
  );
}

function canvasToBlob(canvas: HTMLCanvasElement): Promise<Blob> {
  return new Promise((resolve, reject) => {
    canvas.toBlob(b => { if (b) resolve(b); else reject(new Error('فشل إنشاء الصورة')); }, 'image/png');
  });
}

function ColorToAssetBtn({ color, assetKey, label }: { color: string; assetKey: string; label: string }) {
  const [generating, setGenerating] = useState(false);
  const [done, setDone] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const handleGenerate = async () => {
    setGenerating(true);
    setDone(false);
    try {
      const canvas = canvasRef.current;
      if (!canvas) return;
      const ctx = canvas.getContext('2d');
      if (!ctx) return;
      canvas.width = 200;
      canvas.height = 200;
      ctx.fillStyle = to6Hex(color);
      ctx.fillRect(0, 0, 200, 200);

      const blob = await canvasToBlob(canvas);
      const file = new File([blob], `${assetKey}.png`, { type: 'image/png' });
      const remoteUrl = await uploadAppAsset(file, assetKey);
      const record: AppAssetRecord = {
        id: crypto.randomUUID(),
        key: assetKey,
        name: label,
        type: 'color',
        category: 'الألوان',
        subcategory: 'ألوان المظهر',
        localPath: '',
        remoteUrl,
        defaultValue: color,
        mimeType: 'image/png',
        fileSize: blob.size,
        width: 200,
        height: 200,
        sortOrder: 0,
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      await upsertAppAsset(record);
      setDone(true);
      setTimeout(() => setDone(false), 3000);
    } catch (err) {
      alert('فشل التوليد: ' + (err as Error).message);
    }
    setGenerating(false);
  };

  return (
    <>
      <canvas ref={canvasRef} className="hidden" />
      <button onClick={handleGenerate} disabled={generating}
        className="text-[9px] px-2 py-1 rounded border border-white/10 hover:bg-white/5 disabled:opacity-50 flex items-center gap-1 shrink-0"
        title={`حول ${label} إلى أصل (صورة)`}>
        {done ? <Check className="w-2.5 h-2.5 text-green-400" /> : <Camera className="w-2.5 h-2.5" />}
        {generating ? 'جاري...' : done ? 'تم ✅' : 'أصل'}
      </button>
    </>
  );
}

const vipKeyLabels: Record<string, string> = {
  vip_card_bg: 'خلفية بطاقة VIP',
  vip_purchase_bar: 'شريط شراء VIP',
  vip_coin_icon: 'أيقونة عملة VIP',
  vip_buy_btn: 'زر شراء VIP',
};

function ImagesSection({ config, updateField }: { config: AppConfig; updateField: (field: string, value: unknown) => void }) {
  const [assets, setAssets] = useState<AppAssetRecord[]>([]);

  useEffect(() => {
    getAppAssets({ limit: 100 }).then(res => setAssets(res.data));
  }, []);

  const vipKeys = ['vip_card_bg', 'vip_purchase_bar', 'vip_coin_icon', 'vip_buy_btn'];
  const vipAssets = assets.filter(a => vipKeys.includes(a.key));

  return (
    <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-5">
      <h3 className="text-white text-sm font-semibold">🖼 الصور والطباعة</h3>

      {/* VIP Assets (from app_assets) */}
      <div>
        <h4 className="text-xs text-indigo-300 font-semibold mb-3">صور VIP الحالية من التطبيق</h4>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {vipKeys.map(key => {
            const asset = vipAssets.find(a => a.key === key);
            const url = asset?.remoteUrl || '';
            const label = vipKeyLabels[key] || key;
            return (
              <div key={key} className="bg-[#161618] rounded-xl border border-white/5 p-2">
                <label className="block text-[9px] text-slate-500 mb-1.5">{label}</label>
                {url ? (
                  <img src={url} className="w-full h-16 object-contain rounded-lg bg-black/30 mb-1"
                    onError={e => { (e.target as HTMLImageElement).src = ''; }} />
                ) : (
                  <div className="w-full h-16 rounded-lg bg-black/30 flex items-center justify-center text-[9px] text-slate-600 mb-1">
                    لا توجد صورة
                  </div>
                )}
                <div className="flex gap-1">
                  <label className="flex-1 flex items-center justify-center gap-1 text-[8px] py-1 rounded border border-white/10 hover:bg-white/5 cursor-pointer">
                    <Upload className="w-2.5 h-2.5" />
                    رفع
                    <input type="file" accept="image/*,.svga,.mp4,.gif" onChange={async e => {
                      const file = e.target.files?.[0]; if (!file) return;
                      const url = await uploadAppAsset(file, key);
                      const record: AppAssetRecord = {
                        id: crypto.randomUUID(), key, name: label, type: file.name.endsWith('.svga') ? 'svga' : 'image',
                        category: 'صور VIP', subcategory: 'المظهر', localPath: '', remoteUrl: url,
                        defaultValue: '', mimeType: file.type || 'image/png', fileSize: file.size,
                        width: null, height: null, sortOrder: 0, isActive: true,
                        createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
                      };
                      await upsertAppAsset(record);
                      getAppAssets({ limit: 100 }).then(res => setAssets(res.data));
                    }} className="hidden" />
                  </label>
                  {url && <button onClick={() => { window.open(url, '_blank'); }}
                    className="text-[8px] px-2 py-1 rounded border border-white/10 hover:bg-white/5">عرض</button>}
                </div>
                <span className="text-[8px] text-slate-600 block mt-1 truncate">{asset?.key || key}</span>
              </div>
            );
          })}
        </div>
      </div>

      {/* VIP Background Images (from app_config) */}
      <div className="border-t border-white/5 pt-4">
        <h4 className="text-xs text-indigo-300 font-semibold mb-3">صور الخلفيات (Config)</h4>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {[
            { key: 'vipCardBgImgUrl', label: 'خلفية بطاقة VIP' },
            { key: 'vipPurchaseBarImgUrl', label: 'شريط شراء VIP' },
            { key: 'vipCoinImgUrl', label: 'أيقونة عملة VIP' },
            { key: 'vipBuyBtnImgUrl', label: 'زر شراء VIP' },
          ].map(({ key, label }) => (
            <div key={key}>
              <label className="block text-[10px] text-slate-400 font-bold mb-1.5">{label}</label>
              <div className="flex gap-2 items-start">
                <div className="flex-1 space-y-1">
                  {(config as any)[key] ? (
                    <img src={(config as any)[key]} className="w-full h-16 object-contain rounded-lg border border-white/5 bg-black/20"
                      onError={e => { (e.target as HTMLImageElement).src = ''; }} />
                  ) : (
                    <div className="w-full h-16 rounded-lg border border-dashed border-white/5 bg-black/10 flex items-center justify-center text-[9px] text-slate-600">
                      لا توجد صورة
                    </div>
                  )}
                  <div className="flex gap-1">
                    <label className="flex items-center gap-1 text-[9px] px-2 py-1 rounded border border-white/10 hover:bg-white/5 cursor-pointer">
                      <Upload className="w-2.5 h-2.5" />
                      رفع
                      <input type="file" accept="image/*,.svga" onChange={async e => {
                        const file = e.target.files?.[0]; if (!file) return;
                        const url = await uploadToCloudinary(file, 'config');
                        updateField(key, url);
                      }} className="hidden" />
                    </label>
                    {(config as any)[key] && (
                      <button onClick={() => updateField(key, '')}
                        className="text-[9px] px-2 py-1 rounded border border-rose-500/20 text-rose-400 hover:bg-rose-500/10">مسح</button>
                    )}
                  </div>
                </div>
              </div>
              <input type="text" value={(config as any)[key] || ''}
                onChange={e => updateField(key, e.target.value)}
                placeholder="أو ألصق رابط..." className="w-full mt-1 bg-[#161618] border border-white/10 rounded py-1 px-2 text-[10px] text-white font-mono" />
            </div>
          ))}
        </div>
      </div>

      <div className="border-t border-white/5 pt-4">
        <label className="block text-[10px] text-slate-400 font-bold mb-1.5">اسم التطبيق (App Name)</label>
        <input type="text" value={config.appName || ''}
          onChange={e => updateField('appName', e.target.value)}
          className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white" />
      </div>

      {/* Logo */}
      <div className="border-t border-white/5 pt-4">
        <h4 className="text-xs text-indigo-300 font-semibold mb-3">شعار التطبيق (App Logo)</h4>
        <div className="flex items-center gap-4">
          {config.logoUrl ? (
            <div className="relative">
              <img src={config.logoUrl} className="w-20 h-20 object-contain rounded-lg border border-white/5 bg-black/20"
                onError={e => { (e.target as HTMLImageElement).src = ''; }} />
              <button onClick={() => updateField('logoUrl', '')}
                className="absolute -top-2 -right-2 w-5 h-5 rounded-full bg-rose-500 text-white text-[10px]">×</button>
            </div>
          ) : (
            <label className="w-20 h-20 rounded-lg border-2 border-dashed border-white/10 flex flex-col items-center justify-center cursor-pointer hover:border-indigo-500/50 transition-all">
              <Upload className="w-5 h-5 text-slate-500 mb-1" />
              <span className="text-[8px] text-slate-600">رفع</span>
              <input type="file" accept="image/*,.svga,.gif,.webp,.png" onChange={async e => {
                const file = e.target.files?.[0]; if (!file) return;
                const url = await uploadToCloudinary(file, 'config');
                updateField('logoUrl', url);
              }} className="hidden" />
            </label>
          )}
        </div>
        <input type="text" value={config.logoUrl || ''}
          onChange={e => updateField('logoUrl', e.target.value)}
          placeholder="أو ألصق رابط..." className="w-full mt-2 bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white font-mono" />
      </div>

      {/* Splash */}
      <div className="border-t border-white/5 pt-4">
        <h4 className="text-xs text-indigo-300 font-semibold mb-3">شاشة البداية (Splash)</h4>
        <div className="flex items-center gap-4">
          {config.splashGifUrl ? (
            <div className="relative">
              <img src={config.splashGifUrl} className="w-32 h-32 object-contain rounded-lg border border-white/5 bg-black/20"
                onError={e => { (e.target as HTMLImageElement).src = ''; }} />
              <button onClick={() => updateField('splashGifUrl', '')}
                className="absolute -top-2 -right-2 w-5 h-5 rounded-full bg-rose-500 text-white text-[10px]">×</button>
            </div>
          ) : (
            <label className="w-32 h-32 rounded-lg border-2 border-dashed border-white/10 flex flex-col items-center justify-center cursor-pointer hover:border-indigo-500/50 transition-all">
              <Upload className="w-6 h-6 text-slate-500 mb-1" />
              <span className="text-[9px] text-slate-600">رفع</span>
              <input type="file" accept="image/*,.svga,.gif,.mp4" onChange={async e => {
                const file = e.target.files?.[0]; if (!file) return;
                const url = await uploadToCloudinary(file, 'config');
                updateField('splashGifUrl', url);
              }} className="hidden" />
            </label>
          )}
        </div>
        <input type="text" value={config.splashGifUrl || ''}
          onChange={e => updateField('splashGifUrl', e.target.value)}
          placeholder="أو ألصق رابط..." className="w-full mt-2 bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white font-mono" />
      </div>

      {/* Font & Border */}
      <div className="border-t border-white/5 pt-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-[10px] text-slate-400 font-bold mb-1.5">نوع الخط (Font)</label>
          <select value={config.fontFamily || 'system'}
            onChange={e => updateField('fontFamily', e.target.value)}
            className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white">
            <option value="system">النظام الافتراضي</option>
            <option value="Cairo">Cairo (عربي)</option>
            <option value="Noto Sans Arabic">Noto Sans Arabic</option>
            <option value="Tajawal">Tajawal</option>
            <option value="Almarai">Almarai</option>
          </select>
        </div>
        <div>
          <label className="block text-[10px] text-slate-400 font-bold mb-1.5">نصف القطر: {config.borderRadius ?? 8}px</label>
          <input type="range" min="0" max="24" value={Number.isFinite(config.borderRadius) ? config.borderRadius : 8}
            onChange={e => updateField('borderRadius', Number(e.target.value))}
            className="w-full accent-indigo-500" />
        </div>
      </div>

      {/* Economy Settings */}
      <div className="border-t border-white/5 pt-4">
        <h4 className="text-xs text-indigo-300 font-semibold mb-3">💰 إعدادات الاقتصاد (Economy)</h4>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-[10px] text-slate-400 font-bold mb-1.5">عملات لكل XP شحن (coinsPerRechargeXp)</label>
            <input type="number" min="1" value={config.coinsPerRechargeXp ?? 10}
              onChange={e => updateField('coinsPerRechargeXp', Number(e.target.value))}
              className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white" />
          </div>
          <div>
            <label className="block text-[10px] text-slate-400 font-bold mb-1.5">معدل تحويل الألماس لكوينز (diamondToCoinRate)</label>
            <input type="number" min="1" value={config.diamondToCoinRate ?? 2}
              onChange={e => updateField('diamondToCoinRate', Number(e.target.value))}
              className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white" />
            <p className="text-[9px] text-slate-500 mt-1">يعني {config.diamondToCoinRate || 2} ألماس = 1 كوين</p>
          </div>
        </div>
      </div>
    </div>
  );
}

function RankingSection({ config, updateField }: { config: AppConfig; updateField: (field: string, value: unknown) => void }) {
  const [subTab, setSubTab] = useState('wealth');
  const [frames, setFrames] = useState<any[]>([]);
  const rc = config.rankConfig || {};

  useEffect(() => {
    loadFrames();
  }, []);

  const loadFrames = async () => {
    try {
      const { data, error } = await (await import('../lib/db')).supabase.from('ranking_frames').select('*').order('category').order('rank');
      if (!error) setFrames(data || []);
    } catch {}
  };

  const saveFrame = async (category: string, rank: number, assetUrl: string, assetType: string) => {
    try {
      const { error } = await (await import('../lib/db')).supabase.from('ranking_frames').upsert(
        { category, rank, asset_url: assetUrl, asset_type: assetType },
        { onConflict: 'category,rank' }
      );
      if (!error) loadFrames();
    } catch {}
  };

  const subTabs = [
    { id: 'wealth', label: '💰 الثروة' },
    { id: 'charm', label: '💎 الجاذبية' },
    { id: 'room', label: '🏠 الغرفة' },
  ];

  const colorFields = ['goldColor', 'silverColor', 'bronzeColor', 'pointsColor', 'textColor', 'subTextColor'];

  const rcVal = (cat: string, field: string): string => {
    const prefixed = rc[`${cat}_${field}` as keyof typeof rc] as string | undefined;
    const flat = rc[field as keyof typeof rc] as string | undefined;
    return prefixed || (cat === 'wealth' ? (flat || defaultRankConfig[field]) : defaultRankConfig[`${cat}_${field}`]);
  };

  return (
    <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-white text-sm font-semibold">🏆 إعدادات شاشة الترتيب</h3>
      </div>

      {/* 3 category sub-tabs */}
      <div className="flex gap-2 pb-1 border-b border-white/5">
        {subTabs.map(st => (
          <button key={st.id} onClick={() => setSubTab(st.id)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${subTab === st.id ? 'bg-indigo-500/10 text-indigo-300 border border-indigo-500/10' : 'text-slate-500 hover:text-white'}`}>
            {st.label}
          </button>
        ))}
      </div>

      {/* Per-category colors */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {colorFields.map(field => {
          const label = rankColorFieldLabels[field] || field;
          const val = rcVal(subTab, field);
          return (
            <div key={`${subTab}_${field}`}>
              <label className="block text-[10px] text-slate-400 font-bold mb-1.5">{label}</label>
              <div className="flex gap-2 items-center">
                <input type="color" value={to6Hex(val)}
                  onChange={e => updateField('rankConfig', { ...rc, [`${subTab}_${field}`]: e.target.value })}
                  className="w-10 h-10 rounded cursor-pointer bg-transparent border border-white/10 shrink-0" />
                <input type="text" value={val}
                  onChange={e => updateField('rankConfig', { ...rc, [`${subTab}_${field}`]: e.target.value })}
                  className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono text-left" />
              </div>
              <div className="mt-1 w-full h-2 rounded" style={{ backgroundColor: to6Hex(val) }} />
            </div>
          );
        })}
      </div>

      {/* Background */}
      <div className="border-t border-white/5 pt-3">
        <label className="block text-[10px] text-slate-400 font-bold mb-1.5">خلفية {rankCategoryLabels[subTab]}</label>
        <input type="text" value={rcVal(subTab, 'bg')}
          onChange={e => updateField('rankConfig', { ...rc, [`${subTab}_bg`]: e.target.value })}
          placeholder="Key أو رابط"
          className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono" />
        <RankAssetUpload assetKey={`${subTab}_bgAssetKey`} label="ارفع صورة خلفية"
          accept="image/*,.svga,.mp4,.gif" config={config} updateField={updateField} />
      </div>

      {/* Per-category frame uploads */}
      <div className="border-t border-white/5 pt-3">
        <h4 className="text-xs text-amber-300 font-semibold mb-1">🎞 إطارات {rankCategoryLabels[subTab]}</h4>
        <p className="text-[9px] text-slate-500 mb-2">ارفع ملف (SVGA / VAP / MP4 / GIF) لكل رتبة</p>
        {[1, 2, 3].map(rank => {
          const existing = frames.find((f: any) => f.category === subTab && f.rank === rank);
          const rankLabel = rank === 1 ? 'الذهبي 🥇' : rank === 2 ? 'الفضي 🥈' : 'البرونزي 🥉';
          return (
            <div key={rank} className="flex items-center gap-2 py-1.5 border-b border-white/5 last:border-0">
              <span className="text-[9px] text-slate-400 w-20 shrink-0">{rankLabel}</span>
              {existing ? (
                <span className="text-[8px] text-emerald-400 font-mono truncate flex-1">{existing.asset_url}</span>
              ) : (
                <span className="text-[8px] text-slate-600 flex-1">لا يوجد إطار</span>
              )}
              <label className="flex items-center gap-1 text-[8px] px-2 py-1 rounded border border-white/10 hover:bg-white/5 cursor-pointer shrink-0">
                <Upload className="w-2 h-2" />
                رفع
                <input type="file" accept="image/*,.svga,.mp4,.gif,.vap" className="hidden" onChange={async e => {
                  const file = e.target.files?.[0]; if (!file) return;
                  const url = await (await import('../lib/storage')).uploadAppAsset(file, `rank_frame_${subTab}_${rank}`);
                  const type = file.name.endsWith('.svga') ? 'svga' : file.name.endsWith('.vap') ? 'vap' : 'webp';
                  await saveFrame(subTab, rank, url, type);
                }} />
              </label>
              {existing && (
                <button onClick={async () => {
                  try { await (await import('../lib/db')).supabase.from('ranking_frames').delete().eq('category', subTab).eq('rank', rank); } catch {}
                  loadFrames();
                }} className="text-[8px] px-1.5 py-1 rounded border border-rose-500/20 text-rose-400 hover:bg-rose-500/10 shrink-0">×</button>
              )}
            </div>
          );
        })}
      </div>

      {/* General config */}
      <div className="border-t border-white/5 pt-3 grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-[10px] text-slate-400 font-bold mb-1.5">🏆 أيقونة الكأس (Trophy Icon)</label>
          <input type="text" value={rc.trophyIcon || defaultRankConfig.trophyIcon}
            onChange={e => updateField('rankConfig', { ...rc, trophyIcon: e.target.value })}
            placeholder="Key أو رابط"
            className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono" />
        </div>
        <div>
          <label className="block text-[10px] text-slate-400 font-bold mb-1.5">📝 نص الحالة الفارغة (Empty State)</label>
          <input type="text" value={rc.emptyText || defaultRankConfig.emptyText}
            onChange={e => updateField('rankConfig', { ...rc, emptyText: e.target.value })}
            className="w-full bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono" />
        </div>
      </div>
    </div>
  );
}

export default function VisualManagerPage() {
  const [config, setConfig] = useState<AppConfig>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [activeSection, setActiveSection] = useState('colors');

  useEffect(() => {
    getAppConfig().then(data => { if (data) setConfig(data); setLoading(false); });
  }, []);

  const handleSave = async () => {
    setSaving(true);
    await updateAppConfig(config);
    setSaving(false);
  };

  const updateField = (field: string, value: unknown) =>
    setConfig(p => ({ ...p, [field]: value }));

  const sections = [
    { id: 'colors', icon: Palette, label: '🎨 الألوان' },
    { id: 'gradients', icon: Layers, label: '🌈 تدرجات الغرف' },
    { id: 'chat', icon: MessageSquare, label: '💬 ألوان الشات' },
    { id: 'ranking', icon: Trophy, label: '🏆 الترتيب' },
    { id: 'images', icon: Image, label: '🖼 الصور والنصوص' },
    { id: 'titles', icon: Type, label: '📝 عناوين الشاشات' },
  ];

  if (loading) return <div className="text-slate-500 text-xs">جاري التحميل...</div>;

  return (
    <div className="space-y-6 max-w-4xl" dir="rtl">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-white text-lg font-semibold">مدير المظهر (Visual Manager)</h2>
          <p className="text-slate-500 text-xs mt-0.5">التحكم بكل جوانب المظهر — الألوان، التدرجات، الصور، والنصوص</p>
        </div>
        <button onClick={handleSave} disabled={saving}
          className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-xs text-white font-semibold rounded-lg flex items-center gap-1.5">
          <Save className="w-3.5 h-3.5" /> {saving ? 'جاري الحفظ...' : 'حفظ الكل'}
        </button>
      </div>

      {/* Section tabs */}
      <div className="flex gap-2 overflow-x-auto pb-2">
        {sections.map(s => (
          <button key={s.id} onClick={() => setActiveSection(s.id)}
            className={`flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-medium whitespace-nowrap transition-all ${
              activeSection === s.id ? 'bg-indigo-500/10 text-indigo-300 border border-indigo-500/10' : 'text-slate-400 border border-transparent hover:bg-white/5 hover:text-white'
            }`}>
            <s.icon className="w-3.5 h-3.5" /> {s.label}
          </button>
        ))}
      </div>

      {/* Colors Section */}
      {activeSection === 'colors' && (
        <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
          <h3 className="text-white text-sm font-semibold">🎨 ألوان التطبيق الأساسية</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {Object.entries(defaultColors).map(([key, def]) => {
              const val = (config[key as keyof AppConfig] as string) || def;
              return (
                <div key={key}>
                  <label className="block text-[10px] text-slate-400 font-bold mb-1.5">{colorLabels[key] || key}</label>
                  <div className="flex gap-2 items-center">
                    <input type="color" value={to6Hex(val)}
                      onChange={e => updateField(key, e.target.value)}
                      className="w-10 h-10 rounded cursor-pointer bg-transparent border border-white/10 shrink-0" />
                    <input type="text" value={val}
                      onChange={e => updateField(key, e.target.value)}
                      className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono text-left" />
                    <button onClick={() => updateField(key, def)}
                      className="text-[10px] text-slate-500 hover:text-white p-1 shrink-0" title="إعادة للافتراضي">
                      <RotateCcw className="w-3 h-3" />
                    </button>
                    <ColorToAssetBtn color={val} assetKey={`color_${key}`} label={colorLabels[key] || key} />
                  </div>
                  <div className="mt-1 w-full h-2 rounded" style={{ backgroundColor: to6Hex(val) }} />
                </div>
              );
            })}
          </div>
          <button onClick={() => { Object.entries(defaultColors).forEach(([k, v]) => updateField(k, v)); }}
            className="text-[10px] text-slate-500 hover:text-white flex items-center gap-1 mt-2">
            <RotateCcw className="w-3 h-3" /> إعادة كل الألوان للافتراضي
          </button>
        </div>
      )}

      {/* Room Gradients Section */}
      {activeSection === 'gradients' && (
        <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
          <h3 className="text-white text-sm font-semibold">🌈 تدرجات الغرف</h3>
          <p className="text-[10px] text-slate-500">كل غرفة لها تدرج لوني من لونين</p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            {Object.entries(defaultRoomGradients).map(([key, [c1, c2]]) => {
              const grad = config.roomGradients?.[key];
              const color1 = grad?.[0] || c1;
              const color2 = grad?.[1] || c2;
              return (
                <div key={key} className="space-y-2">
                  <label className="block text-[10px] text-slate-400 font-bold">{gradientLabels[key] || key}</label>
                  <div className="h-14 rounded-xl border border-white/5" style={{ background: `linear-gradient(135deg, ${to6Hex(color1)}, ${to6Hex(color2)})` }} />
                  <div className="flex gap-2">
                    <div className="flex-1">
                      <label className="text-[9px] text-slate-600">اللون 1</label>
                      <div className="flex gap-1 items-center">
                        <input type="color" value={to6Hex(color1)}
                          onChange={e => {
                            const g = { ...(config.roomGradients || {}) };
                            g[key] = [e.target.value, color2];
                            updateField('roomGradients', g);
                          }}
                          className="w-8 h-8 rounded cursor-pointer bg-transparent border border-white/10 shrink-0" />
                        <input type="text" value={color1}
                          onChange={e => {
                            const g = { ...(config.roomGradients || {}) };
                            g[key] = [e.target.value, color2];
                            updateField('roomGradients', g);
                          }}
                          className="flex-1 bg-[#161618] border border-white/10 rounded py-1 px-2 text-[10px] text-white font-mono" />
                        <ColorToAssetBtn color={color1} assetKey={`gradient_${key}_1`} label={`${gradientLabels[key] || key} - لون 1`} />
                      </div>
                    </div>
                    <div className="flex-1">
                      <label className="text-[9px] text-slate-600">اللون 2</label>
                      <div className="flex gap-1 items-center">
                        <input type="color" value={to6Hex(color2)}
                          onChange={e => {
                            const g = { ...(config.roomGradients || {}) };
                            g[key] = [color1, e.target.value];
                            updateField('roomGradients', g);
                          }}
                          className="w-8 h-8 rounded cursor-pointer bg-transparent border border-white/10 shrink-0" />
                        <input type="text" value={color2}
                          onChange={e => {
                            const g = { ...(config.roomGradients || {}) };
                            g[key] = [color1, e.target.value];
                            updateField('roomGradients', g);
                          }}
                          className="flex-1 bg-[#161618] border border-white/10 rounded py-1 px-2 text-[10px] text-white font-mono" />
                        <ColorToAssetBtn color={color2} assetKey={`gradient_${key}_2`} label={`${gradientLabels[key] || key} - لون 2`} />
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Chat Colors Section */}
      {activeSection === 'chat' && (
        <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
          <h3 className="text-white text-sm font-semibold">💬 ألوان فقاعات الشات</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {Object.entries(defaultChatColors).map(([field, def]) => {
              const cc = config.chatColors || {};
              const val = cc[field as keyof typeof cc] || def;
              return (
                <div key={field}>
                  <label className="block text-[10px] text-slate-400 font-bold mb-1.5">{chatColorLabels[field] || field}</label>
                  <div className="flex gap-2 items-center">
                    <input type="color" value={to6Hex(val)}
                      onChange={e => updateField('chatColors', { ...(config.chatColors || {}), [field]: e.target.value })}
                      className="w-10 h-10 rounded cursor-pointer bg-transparent border border-white/10 shrink-0" />
                    <input type="text" value={val}
                      onChange={e => updateField('chatColors', { ...(config.chatColors || {}), [field]: e.target.value })}
                      className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono text-left" />
                    <button onClick={() => updateField('chatColors', { ...(config.chatColors || {}), [field]: def })}
                      className="text-[10px] text-slate-500 hover:text-white p-1 shrink-0" title="إعادة للافتراضي">
                      <RotateCcw className="w-3 h-3" />
                    </button>
                    <ColorToAssetBtn color={to6Hex(val)} assetKey={`chat_${field}`} label={chatColorLabels[field] || field} />
                  </div>
                  <div className="mt-1 w-full h-2 rounded" style={{ backgroundColor: to6Hex(val) }} />
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Ranking Config Section */}
      {activeSection === 'ranking' && (
        <RankingSection config={config} updateField={updateField} />
      )}

      {/* Images & Text Section */}
      {activeSection === 'images' && (
        <ImagesSection config={config} updateField={updateField} />
      )}

      {/* Screen Titles Section */}
      {activeSection === 'titles' && (
        <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
          <h3 className="text-white text-sm font-semibold">📝 عناوين الشاشات</h3>
          <p className="text-[10px] text-slate-500">غير عناوين كل شاشة في التطبيق</p>
          <div className="grid grid-cols-2 gap-3">
            {Object.entries(screenLabels).map(([key, label]) => (
              <div key={key}>
                <label className="block text-[10px] text-slate-400 font-bold mb-1">{label}</label>
                <input type="text" value={config.screenTitles?.[key] || label}
                  onChange={e => {
                    const titles = { ...(config.screenTitles || {}), [key]: e.target.value };
                    updateField('screenTitles', titles);
                  }}
                  className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white" />
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
