
# ============================================================
# سكربت إصلاح مشكلة عدم ظهور طلبات فتح الوكالات في لوحة التحكم
# ============================================================

$ErrorActionPreference = "Stop"

$baseDir = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src"
$typesFile = "$baseDir\types\index.ts"
$agencyFile = "$baseDir\pages\Agency.tsx"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "بدء تطبيق إصلاحات طلبات فتح الوكالات..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ============================================================
# الخطوة 1: التحقق من وجود الملفات
# ============================================================
Write-Host "`n[1/5] التحقق من وجود الملفات..." -ForegroundColor Yellow
if (-not (Test-Path $typesFile)) { throw "ملف الأنواع غير موجود: $typesFile" }
if (-not (Test-Path $agencyFile)) { throw "ملف صفحة الوكالات غير موجود: $agencyFile" }
Write-Host "✅ جميع الملفات موجودة" -ForegroundColor Green

# ============================================================
# الخطوة 2: قراءة محتوى الملفات
# ============================================================
Write-Host "`n[2/5] قراءة محتوى الملفات..." -ForegroundColor Yellow
$typesContent = Get-Content -Path $typesFile -Raw -Encoding UTF8
$agencyContent = Get-Content -Path $agencyFile -Raw -Encoding UTF8
Write-Host "✅ تم قراءة الملفات بنجاح" -ForegroundColor Green

# ============================================================
# الخطوة 3: تعديل ملف types/index.ts
# ============================================================
Write-Host "`n[3/5] تعديل ملف الأنواع (types/index.ts)..." -ForegroundColor Yellow

$agencyOpenInterface = @"

export interface AgencyOpenRequestModel {
  id: string;
  requested_by: string;
  agency_name: string;
  phone?: string;
  agency_id?: string;
  photo_url?: string;
  id_card_url?: string;
  agency_type?: string;
  status: 'pending' | 'approved' | 'rejected';
  note?: string;
  reviewed_by?: string;
  reviewed_at?: string;
  created_at: string;
  updated_at?: string;
  requester?: {
    numeric_id?: string;
    name?: string;
    photo_url?: string;
  };
}
"@

if ($typesContent -match "AgencyOpenRequestModel") {
    Write-Host "⚠️  واجهة AgencyOpenRequestModel موجودة مسبقاً، يتم التخطي..." -ForegroundColor Yellow
} else {
    $withdrawalPattern = "(export interface AgencyWithdrawalRequestModel \{[\s\S]*?created_at: string;\r?\n\})"
    if ($typesContent -match $withdrawalPattern) {
        $match = [regex]::Match($typesContent, $withdrawalPattern)
        $insertPoint = $match.Index + $match.Length
        $newTypesContent = $typesContent.Insert($insertPoint, $agencyOpenInterface)
        Set-Content -Path $typesFile -Value $newTypesContent -Encoding UTF8 -NoNewline
        Write-Host "✅ تم إضافة واجهة AgencyOpenRequestModel بنجاح" -ForegroundColor Green
    } else {
        throw "لم يتم العثور على واجهة AgencyWithdrawalRequestModel لإضافة الواجهة بعدها"
    }
}

# ============================================================
# الخطوة 4: تعديل ملف صفحة الوكالات Agency.tsx
# ============================================================
Write-Host "`n[4/5] تعديل صفحة الوكالات (Agency.tsx)..." -ForegroundColor Yellow

# 4.1 إضافة استيراد الأيقونة FilePlus و AgencyOpenRequestModel و الدوال
if ($agencyContent -notmatch "FilePlus") {
    $oldIconImport = "import { Handshake, Users, UserPlus, Wallet, Target, Settings, CreditCard, ArrowDownToLine } from 'lucide-react';"
    $newIconImport = "import { Handshake, Users, UserPlus, Wallet, Target, Settings, CreditCard, ArrowDownToLine, FilePlus } from 'lucide-react';"
    $agencyContent = $agencyContent.Replace($oldIconImport, $newIconImport)
    Write-Host "   ✅ تم إضافة أيقونة FilePlus" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  أيقونة FilePlus موجودة مسبقاً" -ForegroundColor Yellow
}

if ($agencyContent -notmatch "AgencyOpenRequestModel") {
    $oldTypeImport = @"
  HostAgencyModel, HostAgencyMemberModel, CommissionSettingModel,
  HostMilestoneModel, AgencyJoinRequestModel, AgencyLedgerEntryModel,
  AgencyWithdrawalRequestModel,
} from '../types';
"@
    $newTypeImport = @"
  HostAgencyModel, HostAgencyMemberModel, CommissionSettingModel,
  HostMilestoneModel, AgencyJoinRequestModel, AgencyLedgerEntryModel,
  AgencyWithdrawalRequestModel, AgencyOpenRequestModel,
} from '../types';
"@
    $agencyContent = $agencyContent.Replace($oldTypeImport, $newTypeImport)
    Write-Host "   ✅ تم إضافة استيراد النوع AgencyOpenRequestModel" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  استيراد النوع AgencyOpenRequestModel موجود مسبقاً" -ForegroundColor Yellow
}

if ($agencyContent -notmatch "getAgencyOpenRequests") {
    $oldDbImport = @"
  getHostAgencyJoinRequests, approveJoinRequest, rejectJoinRequest,
  updateAgencyMemberRole, removeAgencyMember,
  getAgencyLedger, getWithdrawalRequests, approveWithdrawal, rejectWithdrawal,
} from '../lib/db';
"@
    $newDbImport = @"
  getHostAgencyJoinRequests, approveJoinRequest, rejectJoinRequest,
  updateAgencyMemberRole, removeAgencyMember,
  getAgencyLedger, getWithdrawalRequests, approveWithdrawal, rejectWithdrawal,
  getAgencyOpenRequests, approveAgencyOpenRequest, rejectAgencyOpenRequest,
} from '../lib/db';
"@
    $agencyContent = $agencyContent.Replace($oldDbImport, $newDbImport)
    Write-Host "   ✅ تم إضافة استيراد دوال طلبات فتح الوكالات" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  استيراد الدوال موجود مسبقاً" -ForegroundColor Yellow
}

# 4.2 إضافة تبويب جديد في مصفوفة tabs
if ($agencyContent -notmatch "'open_requests'") {
    $oldTabs = @"
const tabs = [
  { key: 'agencies', labelKey: 'agency.agencies', icon: Handshake },
  { key: 'members', labelKey: 'agency.members', icon: Users },
"@
    $newTabs = @"
const tabs = [
  { key: 'agencies', labelKey: 'agency.agencies', icon: Handshake },
  { key: 'open_requests', label: 'طلبات فتح وكالة', icon: FilePlus },
  { key: 'members', labelKey: 'agency.members', icon: Users },
"@
    $agencyContent = $agencyContent.Replace($oldTabs, $newTabs)
    Write-Host "   ✅ تم إضافة تبويب طلبات فتح وكالة" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  التبويب موجود مسبقاً" -ForegroundColor Yellow
}

# 4.3 إضافة شرط عرض التبويب في الدالة الرئيسية
if ($agencyContent -notmatch "tab === 'open_requests'") {
    $oldTabRender = @"
      {tab === 'agencies' && <AgenciesTab />}
      {tab === 'members' && <MembersTab />}
"@
    $newTabRender = @"
      {tab === 'agencies' && <AgenciesTab />}
      {tab === 'open_requests' && <OpenRequestsTab />}
      {tab === 'members' && <MembersTab />}
"@
    $agencyContent = $agencyContent.Replace($oldTabRender, $newTabRender)
    Write-Host "   ✅ تم إضافة شرط عرض التبويب" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  شرط عرض التبويب موجود مسبقاً" -ForegroundColor Yellow
}

# 4.4 إضافة مكون OpenRequestsTab قبل نهاية الملف
$openRequestsComponent = @"

/* =============================================================
   OPEN AGENCY REQUESTS TAB - طلبات فتح الوكالات من المستخدمين
   ============================================================= */
function OpenRequestsTab() {
  const [requests, setRequests] = useState<AgencyOpenRequestModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('pending');
  const [rejectNote, setRejectNote] = useState('');
  const [rejectingId, setRejectingId] = useState<string | null>(null);
  const [result, setResult] = useState<{ ok: boolean; msg: string; agency_id?: string; email?: string; password?: string } | null>(null);

  const load = async () => {
    setLoading(true);
    const data = await getAgencyOpenRequests(filter);
    setRequests(data || []);
    setLoading(false);
  };
  useEffect(() => { load(); }, [filter]);

  const handleApprove = async (id: string) => {
    if (!confirm('هل أنت متأكد من الموافقة على فتح هذه الوكالة؟ سيتم إنشاء حساب لوحة التحكم تلقائياً.')) return;
    setResult(null);
    const res = await approveAgencyOpenRequest(id);
    if (res.ok) {
      setResult({ ok: true, msg: 'تمت الموافقة على فتح الوكالة بنجاح!' });
    } else {
      setResult({ ok: false, msg: 'فشل الموافقة: ' + (res.error || 'خطأ غير معروف') });
    }
    load();
  };

  const openRejectDialog = (id: string) => {
    setRejectingId(id);
    setRejectNote('');
  };

  const handleRejectConfirm = async () => {
    if (!rejectingId) return;
    const res = await rejectAgencyOpenRequest(rejectingId, rejectNote);
    if (res.ok) {
      setResult({ ok: true, msg: 'تم رفض الطلب بنجاح' });
    } else {
      setResult({ ok: false, msg: 'فشل الرفض: ' + (res.error || 'خطأ غير معروف') });
    }
    setRejectingId(null);
    load();
  };

  const agencyTypeLabels: Record<string, string> = {
    shipping: 'شحن ماس',
    hosting: 'استضافة',
    mixed: 'مختلط',
  };
  const statusColors: Record<string, string> = {
    pending: 'bg-amber-500/10 text-amber-400',
    approved: 'bg-emerald-500/10 text-emerald-400',
    rejected: 'bg-rose-500/10 text-rose-400',
  };
  const statusLabels: Record<string, string> = {
    pending: 'قيد المراجعة',
    approved: 'تمت الموافقة',
    rejected: 'مرفوض',
  };

  return (
    <div className="space-y-4">
      {result && (
        <div className={`p-3 rounded-lg text-xs border ${result.ok ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400' : 'bg-rose-500/10 border-rose-500/30 text-rose-400'}`}>
          <div className="space-y-1">
            <p className="font-semibold">{result.msg}</p>
            {result.agency_id && (
              <>
                <p>رقم الوكالة: <span className="text-white font-mono">{result.agency_id}</span></p>
                {result.email && <p>البريد: <span className="text-white font-mono">{result.email}</span></p>}
                {result.password && <p>كلمة المرور: <span className="text-white font-mono">{result.password}</span></p>}
              </>
            )}
          </div>
        </div>
      )}

      <div className="flex items-center gap-3">
        <p className="text-slate-500 text-xs">{requests.length} طلب</p>
        <select value={filter} onChange={e => setFilter(e.target.value)}
          className="bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-indigo-500">
          <option value="pending">قيد المراجعة فقط</option>
          <option value="approved">تمت الموافقة</option>
          <option value="rejected">مرفوض</option>
          <option value="">الكل</option>
        </select>
      </div>

      {rejectingId && (
        <div className="bg-[#141417] rounded-2xl border border-rose-500/30 p-4 space-y-3">
          <p className="text-rose-400 text-xs font-semibold">سبب الرفض (اختياري)</p>
          <textarea value={rejectNote} onChange={e => setRejectNote(e.target.value)}
            placeholder="اكتب سبب الرفض هنا..."
            rows={3}
            className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-3 text-xs text-white focus:outline-none focus:border-rose-500 placeholder:text-slate-600 resize-none" />
          <div className="flex gap-2">
            <button onClick={handleRejectConfirm}
              className="text-xs bg-rose-500 hover:bg-rose-600 text-white px-4 py-1.5 rounded-lg font-semibold">تأكيد الرفض</button>
            <button onClick={() => setRejectingId(null)}
              className="text-xs bg-slate-600 hover:bg-slate-500 text-white px-4 py-1.5 rounded-lg">إلغاء</button>
          </div>
        </div>
      )}

      {loading ? (
        <p className="text-slate-500 text-xs text-center py-12">جاري تحميل الطلبات...</p>
      ) : requests.length === 0 ? (
        <div className="text-center py-16">
          <p className="text-slate-600 text-sm">لا توجد طلبات {filter === 'pending' ? 'قيد المراجعة' : filter === 'approved' ? 'مقبولة' : filter === 'rejected' ? 'مرفوضة' : ''}</p>
        </div>
      ) : (
        <div className="space-y-3">
          {requests.map(r => (
            <div key={r.id} className="bg-[#141417] rounded-2xl border border-white/5 p-4">
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-start gap-3 flex-1">
                  {r.requester?.photo_url ? (
                    <img src={r.requester.photo_url} alt="" className="w-10 h-10 rounded-full object-cover border border-white/20 flex-shrink-0" />
                  ) : (
                    <div className="w-10 h-10 rounded-full bg-indigo-500/30 flex items-center justify-center text-xs text-indigo-300 font-bold flex-shrink-0">
                      {(r.requester?.name || r.agency_name || '?')[0]}
                    </div>
                  )}
                  <div className="space-y-1 flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-white text-sm font-semibold">{r.agency_name}</span>
                      <span className={`text-[10px] px-2 py-0.5 rounded-full ${statusColors[r.status]}`}>{statusLabels[r.status]}</span>
                      {r.agency_type && (
                        <span className="text-[10px] px-2 py-0.5 rounded-full bg-purple-500/10 text-purple-400">
                          {agencyTypeLabels[r.agency_type] || r.agency_type}
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-3 flex-wrap">
                      <p className="text-[11px] text-cyan-400 font-mono">
                        مطلوب من: {r.requester?.numeric_id || r.requester?.name || r.requested_by?.slice(0, 10)}
                      </p>
                      {r.phone && <p className="text-[11px] text-slate-400"> {r.phone}</p>}
                    </div>
                    <div className="flex gap-3 mt-2">
                      {r.photo_url && (
                        <a href={r.photo_url} target="_blank" rel="noreferrer" className="text-[10px] text-indigo-400 hover:text-indigo-300">
                           صورة شخصية
                        </a>
                      )}
                      {r.id_card_url && (
                        <a href={r.id_card_url} target="_blank" rel="noreferrer" className="text-[10px] text-indigo-400 hover:text-indigo-300">
                           هوية وطنية
                        </a>
                      )}
                    </div>
                    {r.note && <p className="text-[10px] text-slate-500 mt-1">ملاحظة: {r.note}</p>}
                    <p className="text-[10px] text-slate-600">{new Date(r.created_at).toLocaleString('ar')}</p>
                  </div>
                </div>

                {r.status === 'pending' && !rejectingId && (
                  <div className="flex gap-2 flex-shrink-0">
                    <button onClick={() => handleApprove(r.id)}
                      className="text-[11px] bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30 px-3 py-1.5 rounded-lg font-semibold transition-colors">
                      موافقة وفتح
                    </button>
                    <button onClick={() => openRejectDialog(r.id)}
                      className="text-[11px] bg-rose-500/20 text-rose-400 hover:bg-rose-500/30 px-3 py-1.5 rounded-lg font-semibold transition-colors">
                      رفض
                    </button>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
"@

if ($agencyContent -notmatch "function OpenRequestsTab") {
    $agencyContent = $agencyContent.TrimEnd() + "`r`n" + $openRequestsComponent
    Write-Host "   ✅ تم إضافة مكون OpenRequestsTab" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  مكون OpenRequestsTab موجود مسبقاً" -ForegroundColor Yellow
}

# كتابة الملف المعدل
Set-Content -Path $agencyFile -Value $agencyContent -Encoding UTF8 -NoNewline
Write-Host "   ✅ تم حفظ ملف Agency.tsx" -ForegroundColor Green

# ============================================================
# الخطوة 5: التحقق النهائي
# ============================================================
Write-Host "`n[5/5] التحقق النهائي..." -ForegroundColor Yellow
$finalTypes = Get-Content -Path $typesFile -Raw -Encoding UTF8
$finalAgency = Get-Content -Path $agencyFile -Raw -Encoding UTF8

$allOk = $true
if ($finalTypes -match "AgencyOpenRequestModel") { Write-Host "   ✅ واجهة AgencyOpenRequestModel موجودة" -ForegroundColor Green } else { Write-Host "   ❌ واجهة AgencyOpenRequestModel غير موجودة" -ForegroundColor Red; $allOk = $false }
if ($finalAgency -match "FilePlus") { Write-Host "   ✅ استيراد FilePlus موجود" -ForegroundColor Green } else { Write-Host "   ❌ استيراد FilePlus غير موجود" -ForegroundColor Red; $allOk = $false }
if ($finalAgency -match "getAgencyOpenRequests") { Write-Host "   ✅ استيراد دوال الطلبات موجود" -ForegroundColor Green } else { Write-Host "   ❌ استيراد الدوال غير موجود" -ForegroundColor Red; $allOk = $false }
if ($finalAgency -match "'open_requests'") { Write-Host "   ✅ التبويب موجود في قائمة التبويبات" -ForegroundColor Green } else { Write-Host "   ❌ التبويب غير موجود" -ForegroundColor Red; $allOk = $false }
if ($finalAgency -match "function OpenRequestsTab") { Write-Host "   ✅ مكون OpenRequestsTab موجود" -ForegroundColor Green } else { Write-Host "   ❌ المكون غير موجود" -ForegroundColor Red; $allOk = $false }

Write-Host "`n========================================" -ForegroundColor Cyan
if ($allOk) {
    Write-Host "✅ تم تطبيق جميع الإصلاحات بنجاح!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "`nالخطوات التالية:" -ForegroundColor Yellow
    Write-Host "1. قم بإعادة بناء لوحة التحكم: npm run build"
    Write-Host "2. قم بنشر التحديثات على Vercel"
    Write-Host "3. افتح صفحة الوكالات وستجد تبويب جديد 'طلبات فتح وكالة'"
} else {
    Write-Host "❌ فشل تطبيق بعض الإصلاحات، راجع الأخطاء أعلاه" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    exit 1
}
