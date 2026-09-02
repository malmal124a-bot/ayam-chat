
# ============================================================
# سكربت إصلاح مشكلة طلبات فتح الوكالات - باستخدام .NET مباشرة
# ============================================================

$ErrorActionPreference = "Stop"

$baseDir = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src"
$typesFile = "$baseDir\types\index.ts"
$agencyFile = "$baseDir\pages\Agency.tsx"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "بدء تطبيق الإصلاحات (باستخدام .NET IO)..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Write-TextDirect {
    param([string]$Path, [string]$Content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# ============================================================
# الخطوة 1: التحقق
# ============================================================
Write-Host "`n[1/5] التحقق من الملفات..." -ForegroundColor Yellow
if (-not [System.IO.File]::Exists($typesFile)) { throw "ملف الأنواع غير موجود" }
if (-not [System.IO.File]::Exists($agencyFile)) { throw "ملف Agency غير موجود" }
Write-Host "✅ الملفات موجودة" -ForegroundColor Green

# ============================================================
# الخطوة 2: القراءة باستخدام .NET
# ============================================================
Write-Host "`n[2/5] قراءة المحتويات..." -ForegroundColor Yellow
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$typesContent = [System.IO.File]::ReadAllText($typesFile, $utf8NoBom)
$agencyContent = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)
Write-Host "✅ تم القراءة" -ForegroundColor Green

# ============================================================
# الخطوة 3: تعديل types/index.ts
# ============================================================
Write-Host "`n[3/5] تعديل ملف الأنواع..." -ForegroundColor Yellow

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

if ($typesContent -notmatch "AgencyOpenRequestModel") {
    $withdrawalRegex = [regex]"(export interface AgencyWithdrawalRequestModel \{[\s\S]*?created_at: string;\r?\n\})"
    $match = $withdrawalRegex.Match($typesContent)
    if ($match.Success) {
        $newTypesContent = $typesContent.Insert($match.Index + $match.Length, $agencyOpenInterface)
        Write-TextDirect -Path $typesFile -Content $newTypesContent
        Write-Host "✅ تم إضافة واجهة AgencyOpenRequestModel" -ForegroundColor Green
    } else {
        throw "لم يتم العثور على نمط AgencyWithdrawalRequestModel"
    }
} else {
    Write-Host "⚠️  الواجهة موجودة مسبقاً" -ForegroundColor Yellow
}

# ============================================================
# الخطوة 4: تعديل Agency.tsx
# ============================================================
Write-Host "`n[4/5] تعديل صفحة الوكالات..." -ForegroundColor Yellow

# إعادة قراءة agencyContent لتكون حديثة (في حال تم تعديله قبل)
$agencyContent = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)
$modified = $false

# 4.1 إضافة FilePlus إلى استيراد الأيقونات
if ($agencyContent -notmatch "FilePlus") {
    $old = "import { Handshake, Users, UserPlus, Wallet, Target, Settings, CreditCard, ArrowDownToLine } from 'lucide-react';"
    $new = "import { Handshake, Users, UserPlus, Wallet, Target, Settings, CreditCard, ArrowDownToLine, FilePlus } from 'lucide-react';"
    if ($agencyContent.Contains($old)) {
        $agencyContent = $agencyContent.Replace($old, $new)
        Write-Host "   ✅ FilePlus icon" -ForegroundColor Green
        $modified = $true
    }
} else { Write-Host "   ⚠️  FilePlus موجود" -ForegroundColor Yellow }

# 4.2 إضافة استيراد النوع AgencyOpenRequestModel
if ($agencyContent -notmatch "AgencyOpenRequestModel") {
    $old = @"
  HostAgencyModel, HostAgencyMemberModel, CommissionSettingModel,
  HostMilestoneModel, AgencyJoinRequestModel, AgencyLedgerEntryModel,
  AgencyWithdrawalRequestModel,
} from '../types';
"@
    $new = @"
  HostAgencyModel, HostAgencyMemberModel, CommissionSettingModel,
  HostMilestoneModel, AgencyJoinRequestModel, AgencyLedgerEntryModel,
  AgencyWithdrawalRequestModel, AgencyOpenRequestModel,
} from '../types';
"@
    if ($agencyContent.Contains($old)) {
        $agencyContent = $agencyContent.Replace($old, $new)
        Write-Host "   ✅ استيراد النوع" -ForegroundColor Green
        $modified = $true
    }
} else { Write-Host "   ⚠️  استيراد النوع موجود" -ForegroundColor Yellow }

# 4.3 إضافة استيراد دوال طلبات فتح الوكالات
if ($agencyContent -notmatch "getAgencyOpenRequests") {
    $old = @"
  getHostAgencyJoinRequests, approveJoinRequest, rejectJoinRequest,
  updateAgencyMemberRole, removeAgencyMember,
  getAgencyLedger, getWithdrawalRequests, approveWithdrawal, rejectWithdrawal,
} from '../lib/db';
"@
    $new = @"
  getHostAgencyJoinRequests, approveJoinRequest, rejectJoinRequest,
  updateAgencyMemberRole, removeAgencyMember,
  getAgencyLedger, getWithdrawalRequests, approveWithdrawal, rejectWithdrawal,
  getAgencyOpenRequests, approveAgencyOpenRequest, rejectAgencyOpenRequest,
} from '../lib/db';
"@
    if ($agencyContent.Contains($old)) {
        $agencyContent = $agencyContent.Replace($old, $new)
        Write-Host "   ✅ استيراد الدوال" -ForegroundColor Green
        $modified = $true
    }
} else { Write-Host "   ⚠️  استيراد الدوال موجود" -ForegroundColor Yellow }

# 4.4 إضافة التبويب في قائمة التبويبات
if ($agencyContent -notmatch "'open_requests'") {
    $old = @"
const tabs = [
  { key: 'agencies', labelKey: 'agency.agencies', icon: Handshake },
  { key: 'members', labelKey: 'agency.members', icon: Users },
"@
    $new = @"
const tabs = [
  { key: 'agencies', labelKey: 'agency.agencies', icon: Handshake },
  { key: 'open_requests', label: 'طلبات فتح وكالة', icon: FilePlus },
  { key: 'members', labelKey: 'agency.members', icon: Users },
"@
    if ($agencyContent.Contains($old)) {
        $agencyContent = $agencyContent.Replace($old, $new)
        Write-Host "   ✅ تبويب open_requests" -ForegroundColor Green
        $modified = $true
    }
} else { Write-Host "   ⚠️  التبويب موجود" -ForegroundColor Yellow }

# 4.5 إضافة شرط عرض التبويب
if ($agencyContent -notmatch "tab === 'open_requests'") {
    $old = @"
      {tab === 'agencies' && <AgenciesTab />}
      {tab === 'members' && <MembersTab />}
"@
    $new = @"
      {tab === 'agencies' && <AgenciesTab />}
      {tab === 'open_requests' && <OpenRequestsTab />}
      {tab === 'members' && <MembersTab />}
"@
    if ($agencyContent.Contains($old)) {
        $agencyContent = $agencyContent.Replace($old, $new)
        Write-Host "   ✅ شرط عرض التبويب" -ForegroundColor Green
        $modified = $true
    }
} else { Write-Host "   ⚠️  شرط العرض موجود" -ForegroundColor Yellow }

# 4.6 إضافة مكون OpenRequestsTab
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
    Write-Host "   ✅ مكون OpenRequestsTab" -ForegroundColor Green
    $modified = $true
} else { Write-Host "   ⚠️  المكون موجود" -ForegroundColor Yellow }

# حفظ Agency.tsx
Write-TextDirect -Path $agencyFile -Content $agencyContent
Write-Host "   ✅ تم حفظ Agency.tsx" -ForegroundColor Green

# ============================================================
# الخطوة 5: التحقق النهائي
# ============================================================
Write-Host "`n[5/5] التحقق النهائي..." -ForegroundColor Yellow
$finalTypes = [System.IO.File]::ReadAllText($typesFile, $utf8NoBom)
$finalAgency = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)

$allOk = $true
$checks = @(
    @("واجهة AgencyOpenRequestModel", ($finalTypes -match "AgencyOpenRequestModel")),
    @("استيراد FilePlus", ($finalAgency -match "FilePlus")),
    @("استيراد getAgencyOpenRequests", ($finalAgency -match "getAgencyOpenRequests")),
    @("تبويب open_requests", ($finalAgency -match "'open_requests'")),
    @("مكون OpenRequestsTab", ($finalAgency -match "function OpenRequestsTab"))
)

foreach ($chk in $checks) {
    if ($chk[1]) { Write-Host "   ✅ $($chk[0])" -ForegroundColor Green }
    else { Write-Host "   ❌ $($chk[0])" -ForegroundColor Red; $allOk = $false }
}

Write-Host "`n========================================" -ForegroundColor Cyan
if ($allOk) {
    Write-Host "✅ كل شيء تمام! الإصلاحات تم تطبيقها بنجاح." -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "`n👉 الآن قم بتنفيذ هذه الأوامر:" -ForegroundColor Yellow
    Write-Host "   cd ..\admincore-dashboard"
    Write-Host "   npm run build"
    Write-Host "   ثم انشر على Vercel أو شغّل محلياً بـ npm run dev"
} else {
    Write-Host "❌ بعض العناصر مفقودة، راجع الأعلى" -ForegroundColor Red
    exit 1
}
