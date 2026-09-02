
# ============================================================
# استبدال المكون المكسور بالصحيح من ملف نصي
# ============================================================

$agencyFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\pages\Agency.tsx"
$correctFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\ayam\OpenRequestsTab_correct.txt"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$content = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)
$correctComponent = [System.IO.File]::ReadAllText($correctFile, $utf8NoBom).Trim()

Write-Host "استبدال مكون OpenRequestsTab..." -ForegroundColor Yellow

# البحث عن بداية ونهاية المكون المكسور
# البداية: تعليق /* ===== ... OPEN AGENCY REQUESTS TAB
$startComment = "OPEN AGENCY REQUESTS TAB - طلبات فتح الوكالات من المستخدمين"
$startIdx = $content.IndexOf($startComment)
if ($startIdx -lt 0) {
    Write-Host "❌ لم يتم العثور على تعليق بداية المكون" -ForegroundColor Red
    # محاولة بحث عن بدالة الدالة مباشرة
    $startIdx = $content.IndexOf("function OpenRequestsTab()")
    if ($startIdx -lt 0) { throw "لم يتم العثور على المكون أصلاً!" }
    # العودة للخلف قليلاً لإزالة التعليق السابق إن وجد
    $prevComment = $content.LastIndexOf("/*", [Math]::Max(0, $startIdx - 200))
    if ($prevComment -gt 0) { $startIdx = $prevComment }
}
# العودة للخلف للوصول إلى بداية التعليق
$commentStart = $content.LastIndexOf("/*", [Math]::Max(0, $startIdx - 10))
if ($commentStart -gt 0) { $startIdx = $commentStart - 0; $startIdx = $commentStart }
Write-Host "✅ تم العثور على بداية المكون عند: $startIdx" -ForegroundColor Green

# البحث عن نهاية المكون: أقواس متوازنة للدالة
# نقوم بالبدء من قوس افتتاح الدالة الأول بعد اسمها
$braceStart = $content.IndexOf("{", $content.IndexOf("function OpenRequestsTab"))
if ($braceStart -lt 0) { throw "لم يتم إيجاد قوس افتتاح الدالة" }

$depth = 0
$endIdx = $braceStart
for ($i = $braceStart; $i -lt $content.Length; $i++) {
    $ch = $content[$i]
    if ($ch -eq '{') { $depth++ }
    elseif ($ch -eq '}') {
        $depth--
        if ($depth -eq 0) {
            $endIdx = $i + 1
            break
        }
    }
}
Write-Host "✅ تم العثور على نهاية المكون عند: $endIdx (طوله: $($endIdx - $startIdx) محرف)" -ForegroundColor Green

# تنفيذ الاستبدال
$before = $content.Substring(0, $startIdx)
$after = $content.Substring($endIdx)
$newContent = $before + $correctComponent + "`r`n" + $after

# حفظ الملف الجديد
[System.IO.File]::WriteAllText($agencyFile, $newContent, $utf8NoBom)
Write-Host "✅ تم الاستبدال بنجاح" -ForegroundColor Green

exit 0
