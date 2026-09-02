
# ============================================================
# سكربت إكمال الإصلاحات الناقصة - يستخدم Regex بدلاً من مطابقة نصية دقيقة
# ============================================================

$ErrorActionPreference = "Stop"

$agencyFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\pages\Agency.tsx"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "إكمال الإصلاحات الناقصة باستخدام Regex" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# قراءة الملف الحالي
$content = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)
$originalContent = $content
$changed = $false

Write-Host "`nفحص الحالة الحالية:" -ForegroundColor Yellow

# ------------------------------------------------------------
# إضافة تبويب open_requests في مصفوفة tabs (إذا لم يكن موجوداً)
# ------------------------------------------------------------
if ($content -notmatch "'open_requests'") {
    Write-Host "   ❌ تبويب open_requests غير موجود - جاري الإضافة" -ForegroundColor Red

    # البحث عن نمط مصفوفة tabs باستخدام regex
    $pattern = '(const tabs = \[\s*\{ key: \x27agencies\x27[^\}]*\},\s*)'
    $replacement = @'
$1  { key: 'open_requests', label: 'طلبات فتح وكالة', icon: FilePlus },
'@
    $newContent = [regex]::Replace($content, $pattern, $replacement)
    if ($newContent -ne $content) {
        $content = $newContent
        Write-Host "   ✅ تم إضافة تبويب open_requests" -ForegroundColor Green
        $changed = $true
    } else {
        Write-Host "   ⚠️  لم يتم العثور على نمط التبويبات" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✅ تبويب open_requests موجود" -ForegroundColor Green
}

# ------------------------------------------------------------
# إضافة شرط عرض التبويب (tab === 'open_requests')
# ------------------------------------------------------------
if ($content -notmatch "tab === \x27open_requests\x27") {
    Write-Host "   ❌ شرط عرض التبويب غير موجود - جاري الإضافة" -ForegroundColor Red

    $pattern = "(\{tab === \x27agencies\x27 && <AgenciesTab /> \}\s*)"
    $replacement = @'
$1      {tab === 'open_requests' && <OpenRequestsTab />}
'@
    $newContent = [regex]::Replace($content, $pattern, $replacement)
    if ($newContent -ne $content) {
        $content = $newContent
        Write-Host "   ✅ تم إضافة شرط عرض التبويب" -ForegroundColor Green
        $changed = $true
    } else {
        Write-Host "   ⚠️  لم يتم العثور على نمط شرط العرض" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✅ شرط عرض التبويب موجود" -ForegroundColor Green
}

# ------------------------------------------------------------
# إضافة استيراد النوع AgencyOpenRequestModel (إذا لم يكن موجوداً)
# ------------------------------------------------------------
if ($content -notmatch "AgencyOpenRequestModel,") {
    Write-Host "   ❌ استيراد النوع AgencyOpenRequestModel غير موجود - جاري الإضافة" -ForegroundColor Red

    $pattern = "(AgencyWithdrawalRequestModel,)(\s*\} from \x27\.\./types\x27;)"
    $replacement = @'
AgencyWithdrawalRequestModel, AgencyOpenRequestModel,$2
'@
    $newContent = [regex]::Replace($content, $pattern, $replacement)
    if ($newContent -ne $content) {
        $content = $newContent
        Write-Host "   ✅ تم إضافة استيراد النوع" -ForegroundColor Green
        $changed = $true
    } else {
        Write-Host "   ⚠️  لم يتم العثور على نمط استيراد الأنواع" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✅ استيراد النوع موجود" -ForegroundColor Green
}

# ------------------------------------------------------------
# إضافة استيراد دوال طلبات فتح الوكالات (إذا لم تكن موجودة)
# ------------------------------------------------------------
if ($content -notmatch "getAgencyOpenRequests,") {
    Write-Host "   ❌ استيراد دوال الطلبات غير موجود - جاري الإضافة" -ForegroundColor Red

    $pattern = "(rejectWithdrawal,)(\s*\} from \x27\.\./lib/db\x27;)"
    $replacement = @'
rejectWithdrawal,
  getAgencyOpenRequests, approveAgencyOpenRequest, rejectAgencyOpenRequest,$2
'@
    $newContent = [regex]::Replace($content, $pattern, $replacement)
    if ($newContent -ne $content) {
        $content = $newContent
        Write-Host "   ✅ تم إضافة استيراد الدوال" -ForegroundColor Green
        $changed = $true
    } else {
        Write-Host "   ⚠️  لم يتم العثور على نمط استيراد الدوال" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✅ استيراد الدوال موجود" -ForegroundColor Green
}

# ------------------------------------------------------------
# حفظ الملف إذا تغير
# ------------------------------------------------------------
if ($changed) {
    [System.IO.File]::WriteAllText($agencyFile, $content, $utf8NoBom)
    Write-Host "`n✅ تم حفظ التعديلات على الملف" -ForegroundColor Green
} else {
    Write-Host "`nℹ️  لم تكن هناك تعديلات مطلوبة" -ForegroundColor Cyan
}

# ------------------------------------------------------------
# التحقق النهائي الشامل
# ------------------------------------------------------------
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "التحقق النهائي الشامل" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$final = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)
$typesFinal = [System.IO.File]::ReadAllText("c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\types\index.ts", $utf8NoBom)

$allChecks = @(
    @("types: واجهة AgencyOpenRequestModel", ($typesFinal -match "AgencyOpenRequestModel")),
    @("Agency: استيراد FilePlus icon", ($final -match "FilePlus")),
    @("Agency: استيراد النوع AgencyOpenRequestModel", ($final -match "AgencyOpenRequestModel,")),
    @("Agency: استيراد getAgencyOpenRequests", ($final -match "getAgencyOpenRequests,")),
    @("Agency: تبويب open_requests", ($final -match "'open_requests'")),
    @("Agency: شرط عرض التبويب", ($final -match "tab === \x27open_requests\x27")),
    @("Agency: مكون OpenRequestsTab", ($final -match "function OpenRequestsTab"))
)

$allOk = $true
foreach ($c in $allChecks) {
    if ($c[1]) {
        Write-Host "   ✅ $($c[0])" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $($c[0])" -ForegroundColor Red
        $allOk = $false
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
if ($allOk) {
    Write-Host "🎉 كل الإصلاحات مكتملة بنجاح!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "`n👉 الخطوات التالية:" -ForegroundColor Yellow
    Write-Host "   1. cd c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard"
    Write-Host "   2. npm run build   (للبناء والتحقق من عدم وجود أخطاء TypeScript)"
    Write-Host "   3. npm run dev     (للتجربة المحلية)"
    Write-Host "   أو انشر مباشرة على Vercel"
    exit 0
} else {
    Write-Host "❌ لا تزال هناك بعض المشكلات" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    exit 1
}
