import React, { useEffect, useState } from 'react';
import { AppAssetRecord } from '../types';
import { getAppAssets, updateAppAsset, deleteAppAsset } from '../lib/db';
import { uploadAppAsset } from '../lib/storage';
import { SCREEN_ASSETS, SCREEN_ORDER } from '../lib/screenAssets';
import { Upload } from 'lucide-react';

const _wordMap: Record<string, string> = {
  room: 'غرفة', bg: 'خلفية', ic: 'أيقونة', pre: 'محدد', nor: 'عادي',
  mic: 'مايك', seat: 'مقعد', gift: 'هدية', create: 'إنشاء', chat: 'محادثة',
  emoj: 'إيموجي', exit: 'خروج', follow: 'متابعة', function: 'وظائف',
  game: 'لعبة', hot: 'نشط', lock: 'قفل', notice: 'إشعار', online: 'متصل',
  owner: 'مالك', photo: 'صورة', pwd: 'كلمة سر', set: 'إعدادات',
  user: 'مستخدم', window: 'نافذة', discover: 'استكشاف', search: 'بحث',
  item: 'عنصر', tab: 'تبويب', mine: 'حسابي', wallet: 'محفظة',
  level: 'مستوى', backpack: 'حقيبة', mall: 'متجر', setting: 'إعدادات',
  feedback: 'اقتراح', report: 'بلاغ', phone: 'هاتف', camera: 'كاميرا',
  avatar: 'صورة شخصية', edit: 'تعديل', delete: 'حذف', black: 'أسود',
  close: 'إغلاق', back: 'رجوع', next: 'التالي', common: 'عام',
  gold: 'ذهبي', diamond: 'ألماسة', sex: 'جنس', male: 'ذكر', female: 'أنثى',
  super: 'مشرف', frame: 'إطار', giftAnim: 'هدية متحركة', speaking: 'متحدث',
  wave: 'موجة', miao: 'مياو', rank: 'ترتيب', border: 'حدود',
  splash: 'شاشة البداية', logo: 'شعار', social: 'تواصل', sharing: 'مشاركة',
  country: 'دولة', more: 'المزيد', header: 'رأس', indicator: 'مؤشر',
  recent: 'الأخيرة', teaming: 'فريق', music: 'موسيقى', hobby: 'هواية',
  party: 'حفلة', friend: 'صديق', label: 'تصنيف', star: 'نجمة',
  lucky: 'محظوظ', combo: 'كومبو', time: 'وقت', numOpen: 'فتح الرقم',
  bag: 'حقيبة', select: 'اختيار', panel: 'لوحة', member: 'عضو',
  float: 'عائم', cancel: 'إلغاء', volume: 'صوت', mixer: 'خلاط',
  effect: 'تأثير', style: 'نمط', info: 'معلومات', operate: 'تحكم',
  onlineInfo: 'معلومات الاتصال', package: 'حزمة', windowFloat: 'نافذة عائمة',
  followNor: 'متابعة عادي', followPre: 'متابعة محدد',
  allSelectNor: 'اختيار الكل عادي', allSelectPre: 'اختيار الكل محدد',
  luckyGiftAnim: 'رسوم هدية محظوظة', luckyGiftCoin: 'عملة الهدية المحظوظة',
  luckyGiftBg: 'خلفية الهدية المحظوظة',
  comboTime: 'وقت الكومبو', comboLuckyNor: 'كومبو محظوظ عادي',
  comboLuckyPre: 'كومبو محظوظ محدد',
  starLabel: 'تصنيف نجمة', musicLabel: 'تصنيف موسيقى',
  luckyLabel: 'تصنيف محظوظ',
  micCharmMale: 'مايك جاذبية ذكر', micSeatDefault: 'مقعد مايك افتراضي',
  micSeatBig: 'مقعد مايك كبير', micSeatLock: 'مقعد مايك مقفول',
  micSeatMute: 'مقعد مايك كتم', micphone: 'مايكروفون',
  btnDian: 'زر ديان', next2: 'التالي 2', next3: 'التالي 3', next4: 'التالي 4',
  back2: 'رجوع 2', backWhite: 'رجوع أبيض', nextBlack: 'التالي أسود',
  nextWhite: 'التالي أبيض',
  userId: 'معرف المستخدم', idCopy: 'نسخ المعرف',
  btnEdit: 'زر تعديل', photoAdd: 'إضافة صورة',
  phoneDown: 'تنزيل الهاتف', googlePay: 'Google Pay',
  vipCenter: 'مركز VIP', vipLabel: 'تصنيف VIP', vipGo: 'الذهاب إلى VIP',
  tabVip: 'تبويب VIP',
  coinBag: 'كيس العملات', detail: 'التفاصيل', filter: 'تصفية',
  walletHeader: 'رأس المحفظة',
  roomItem: 'عنصر الغرفة', itemChat: 'عنصر المحادثة',
  itemMusic: 'عنصر الموسيقى', itemGame: 'عنصر اللعبة',
  itemHobby: 'عنصر الهواية', itemParty: 'عنصر الحفلة',
  itemFriend: 'عنصر الصديق', itemRoom: 'عنصر الغرفة',
  countryMore: 'دولة المزيد', roomHot: 'غرفة نشطة',
  tabFollow: 'تبويب متابعة', tabRecent: 'تبويب الأخيرة',
  tabIndicator: 'مؤشر التبويب',
  superAdmin: 'مشرف',
  fmWave: 'موجة FM', speakingWave: 'موجة متحدث',
  rankBorder: 'حدود الترتيب',
  imgLogo: 'شعار', imgPre: 'الصورة المبدئية',
  introduceBg: 'خلفية التعريف',
  headerMember: 'رأس العضو', selectNum: 'اختيار الرقم',
  lockState: 'حالة القفل', pwdLockOff: 'قفل كلمة السر مغلق',
  pwdLockOpen: 'قفل كلمة السر مفتوح',
  micDown: 'مايك لأسفل', micOn: 'مايك شغال', micOff: 'مايك طافي',
  micOperate: 'تشغيل المايك',
  userinfo: 'معلومات المستخدم', userInfo: 'معلومات المستخدم',
  menu: 'قائمة', popup: 'منبثق', options: 'خيارات',
  banner: 'لافتة', top: 'أعلى', bottom: 'أسفل', center: 'وسط',
  notification: 'إشعار', message: 'رسالة', system: 'نظام',
  information: 'معلومات',
  placeholder: 'مكان',
  bd: 'مدير', cp: 'منسق', agency: 'وكالة', union: 'نقابة',
};

function constantToArabic(constant: string): string {
  let name = constant;
  // Strip common type suffixes
  name = name.replace(/(Ic|Pre|Nor|Bg|Img|Svga|Webp|Png|Gif|Jpg|Jpeg)$/g, '');
  // Split camelCase
  const parts = name.split(/(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])/g);
  const mapped = parts.map(p => {
    const lower = p.toLowerCase();
    return _wordMap[lower] || lower;
  });
  return mapped.join(' ');
}

export default function AppAssetsPage() {
  const [tab, setTab] = useState(SCREEN_ORDER[0]);
  const [assets, setAssets] = useState<Record<string, AppAssetRecord>>({});
  const [uploading, setUploading] = useState<string | null>(null);

  useEffect(() => {
    loadAssets();
  }, []);

  const loadAssets = async () => {
    try {
      const res = await getAppAssets({ limit: 5000 });
      const map: Record<string, AppAssetRecord> = {};
      for (const a of res.data) {
        map[a.key] = a;
      }
      setAssets(map);
    } catch {}
  };

  const handleUpload = async (entry: { fullKey: string; constant: string; path: string }) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*,.svga,.mp4,.gif,.vap,.json';
    input.onchange = async () => {
      const file = input.files?.[0];
      if (!file) return;
      setUploading(entry.fullKey);
      try {
        const url = await uploadAppAsset(file, entry.fullKey);
        const existing = assets[entry.fullKey];
        const record: AppAssetRecord = {
          id: existing?.id || crypto.randomUUID(),
          key: entry.fullKey,
          name: entry.constant,
          type: file.name.endsWith('.svga') ? 'svga' : file.name.endsWith('.vap') ? 'vap' : file.name.endsWith('.json') ? 'lottie' : 'image',
          category: tab,
          subcategory: 'R.xxx',
          localPath: entry.path,
          remoteUrl: url,
          defaultValue: '',
          mimeType: file.type || 'application/octet-stream',
          fileSize: file.size,
          width: null,
          height: null,
          sortOrder: 0,
          isActive: true,
          createdAt: existing?.createdAt || new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        await (await import('../lib/db')).upsertAppAsset(record);
        await loadAssets();
      } catch (err) {
        alert('فشل الرفع: ' + (err as Error).message);
      }
      setUploading(null);
    };
    input.click();
  };

  const handleDelete = async (fullKey: string) => {
    const asset = assets[fullKey];
    if (!asset) return;
    if (!confirm(`حذف "${asset.name}"؟`)) return;
    try {
      await deleteAppAsset(asset.id);
      await loadAssets();
    } catch {}
  };

  const screenCategories = SCREEN_ORDER.filter(s => {
    const data = SCREEN_ASSETS[s];
    return data && data.assets.length > 0;
  });

  const currentAssets = SCREEN_ASSETS[tab]?.assets || [];

  return (
    <div className="space-y-4" dir="rtl">
      <div>
        <h2 className="text-white text-lg font-semibold">📁 أصول الشاشات (R.xxx)</h2>
        <p className="text-slate-500 text-xs mt-0.5">اختر شاشة لعرض كل الأصول المرجعية من r.dart مع إمكانية رفع بديل أو مسحه</p>
      </div>

      {/* Screen tabs */}
      <div className="flex gap-1.5 overflow-x-auto pb-1">
        {screenCategories.map(s => {
          const count = currentAssets.length;
          const isActive = tab === s;
          return (
            <button key={s} onClick={() => setTab(s)}
              className={`shrink-0 px-2.5 py-1.5 text-[10px] font-semibold rounded-lg transition-colors ${
                isActive ? 'bg-indigo-600 text-white' : 'bg-[#161618] text-slate-400 border border-white/10 hover:bg-white/5'
              }`}>
              {SCREEN_ASSETS[s]?.label || s} ({currentAssets.length})
            </button>
          );
        })}
      </div>

      {/* Asset grid */}
      {currentAssets.length === 0 ? (
        <div className="text-slate-600 text-xs text-center py-12">لا توجد أصول لهذه الشاشة</div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-2">
          {currentAssets.map(entry => {
            const asset = assets[entry.fullKey];
            const isSvg = entry.fullKey.endsWith('_svga');
            const isJson = entry.fullKey.endsWith('_json');
            return (
              <div key={entry.fullKey} className="bg-[#141417] rounded-xl border border-white/5 overflow-hidden group">
                {/* Preview */}
                {asset?.remoteUrl ? (
                  <div className="relative">
                    {isSvg ? (
                      <div className="w-full h-20 flex items-center justify-center bg-black/30 text-[9px] text-emerald-400/60">SVGA</div>
                    ) : isJson ? (
                      <div className="w-full h-20 flex items-center justify-center bg-black/30 text-[9px] text-emerald-400/60">Lottie</div>
                    ) : (
                      <img src={asset.remoteUrl} className="w-full h-20 object-contain bg-black/30"
                        onError={e => { (e.target as HTMLImageElement).src = ''; }} />
                    )}
                    <div className="absolute inset-0 bg-black/0 group-hover:bg-black/40 transition-all flex items-center justify-center opacity-0 group-hover:opacity-100">
                      {uploading === entry.fullKey ? (
                        <span className="text-[9px] text-white">جاري...</span>
                      ) : (
                        <button onClick={() => handleUpload(entry)}
                          className="text-[9px] px-2 py-1 rounded bg-white/10 text-white hover:bg-white/20">تغيير</button>
                      )}
                    </div>
                  </div>
                ) : (
                  <div className="w-full h-20 flex flex-col items-center justify-center bg-black/20 gap-1">
                    {uploading === entry.fullKey ? (
                      <span className="text-[9px] text-slate-400">جاري...</span>
                    ) : (
                      <>
                        <div className="text-[9px] text-slate-600">لا يوجد بديل</div>
                        <button onClick={() => handleUpload(entry)}
                          className="flex items-center gap-1 text-[8px] px-2 py-1 rounded border border-dashed border-white/10 text-slate-500 hover:border-indigo-500/50 hover:text-indigo-300 transition-all">
                          <Upload className="w-2.5 h-2.5" /> رفع
                        </button>
                      </>
                    )}
                  </div>
                )}
                <div className="p-2 space-y-1">
                  <div className="text-[9px] text-white truncate" title={entry.constant}>{constantToArabic(entry.constant)}</div>
                  <div className="text-[7px] text-slate-500 font-mono truncate" dir="ltr" title={entry.constant}>{entry.constant}</div>
                  <div className="text-[7px] text-slate-600 truncate" title={entry.path}>{entry.path}</div>
                  {asset?.remoteUrl && (
                    <div className="flex gap-1 pt-1">
                      <button onClick={() => window.open(asset.remoteUrl, '_blank')}
                        className="text-[7px] px-1.5 py-0.5 rounded border border-white/10 text-slate-500 hover:text-white hover:bg-white/5">🔗</button>
                      <button onClick={() => handleDelete(entry.fullKey)}
                        className="text-[7px] px-1.5 py-0.5 rounded border border-rose-500/20 text-rose-400/60 hover:text-rose-400 hover:bg-rose-500/10">🗑</button>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
