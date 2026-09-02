
# قراءة النصوص الأصلية المطلوبة للإصلاح
$dbFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\lib\db.ts"
$agencyFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\pages\Agency.tsx"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

Write-Host "=== دالة approveAgencyOpenRequest الحالية في db.ts ===" -ForegroundColor Cyan
$db = [System.IO.File]::ReadAllText($dbFile, $utf8NoBom)
$startIdx = $db.IndexOf("export async function approveAgencyOpenRequest")
if ($startIdx -gt 0) {
    $endFunc = $db.IndexOf("export async function", $startIdx + 50)
    if ($endFunc -lt 0) { $endFunc = [Math]::Min($db.Length, $startIdx + 400) }
    Write-Host $db.Substring($startIdx, $endFunc - $startIdx)
} else { Write-Host "❌ لم يتم إيجاد الدالة" -ForegroundColor Red }

Write-Host "`n=== دالة rejectAgencyOpenRequest الحالية في db.ts ===" -ForegroundColor Cyan
$startIdx2 = $db.IndexOf("export async function rejectAgencyOpenRequest")
if ($startIdx2 -gt 0) {
    $endFunc2 = $db.IndexOf("export async function", $startIdx2 + 50)
    if ($endFunc2 -lt 0) { $endFunc2 = [Math]::Min($db.Length, $startIdx2 + 300) }
    Write-Host $db.Substring($startIdx2, $endFunc2 - $startIdx2)
} else { Write-Host "❌ لم يتم إيجاد الدالة" -ForegroundColor Red }

Write-Host "`n=== handleApprove الحالي في Agency.tsx ===" -ForegroundColor Cyan
$agency = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)
$startIdx3 = $agency.IndexOf("const handleApprove = async")
if ($startIdx3 -gt 0) {
    $endFunc3 = $agency.IndexOf("};", $startIdx3 + 100)
    if ($endFunc3 -gt 0) { Write-Host $agency.Substring($startIdx3, ($endFunc3+2) - $startIdx3) }
} else { Write-Host "❌ لم يتم إيجاد الدالة" -ForegroundColor Red }
