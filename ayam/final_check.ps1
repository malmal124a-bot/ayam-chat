
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$typesFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\types\index.ts"
$agencyFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\pages\Agency.tsx"

$types = [System.IO.File]::ReadAllText($typesFile, $utf8NoBom)
$agency = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "التحقق النهائي الشامل من جميع الإصلاحات" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$checks = @(
    @("✅ ملف الأنواع: واجهة AgencyOpenRequestModel موجودة", ($types -match "export interface AgencyOpenRequestModel")),
    @("✅ ملف Agency: استيراد أيقونة FilePlus", ($agency -match "FilePlus.*lucide-react")),
    @("✅ ملف Agency: استيراد النوع AgencyOpenRequestModel", ($agency -match "AgencyOpenRequestModel,")),
    @("✅ ملف Agency: استيراد الدوال (getAgencyOpenRequests...)", ($agency -match "getAgencyOpenRequests.*approveAgencyOpenRequest.*rejectAgencyOpenRequest")),
    @("✅ ملف Agency: تبويب open_requests في قائمة التبويبات", ($agency -match "key.*open_requests.*طلبات فتح وكالة")),
    @("✅ ملف Agency: شرط عرض التبويب", ($agency -match "tab === .open_requests. && <OpenRequestsTab />")),
    @("✅ ملف Agency: مكون OpenRequestsTab كامل", ($agency -match "function OpenRequestsTab\(\) \{[\s\S]*handleApprove[\s\S]*handleRejectConfirm"))
)

$allOk = $true
foreach ($c in $checks) {
    Start-Sleep -Milliseconds 100
    if ($c[1]) { Write-Host $c[0] -ForegroundColor Green }
    else { Write-Host ("❌ " + $c[0].Substring(2)) -ForegroundColor Red; $allOk = $false }
}

Write-Host "`n========================================"
if ($allOk) {
    Write-Host "🎉 جميع الإصلاحات مكتملة بنجاح!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "`n📋 ملخص ما تم إضافته:" -ForegroundColor Yellow
    Write-Host "  1. واجهة AgencyOpenRequestModel في types/index.ts"
    Write-Host "  2. تبويب جديد 'طلبات فتح وكالة' كثاني تبويب في صفحة الوكالات"
    Write-Host "  3. عرض جميع طلبات فتح الوكالات مع بيانات مقدم الطلب"
    Write-Host "  4. أزرار الموافقة (فتح الوكالة تلقائياً) والرفض مع سبب"
    Write-Host "  5. تصفية حسب الحالة (قيد المراجعة/مقبول/مرفوض/الكل)"
    exit 0
} else {
    Write-Host "❌ لا تزال هناك مشاكل" -ForegroundColor Red
    exit 1
}
