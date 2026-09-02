
# إصلاح الـ href الخاص بزر فتح لوحة الوكالة (الـ backticks مفقودة)
$agencyFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\pages\Agency.tsx"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$content = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)

Write-Host "بحث عن زر فتح لوحة الوكالة للإصلاح..." -ForegroundColor Yellow

# النمط الخاطئ الذي تم إنشاؤه: href={$AGENCY_DASH_URL#agency_id=... password=...} (بدون backticks)
$brokenPattern = 'href=\{\$AGENCY_DASH_URL#agency_id=\$\{result\.agency_id\}&email=\$\{result\.email\}&password=\$\{result\.password\}\}'
$regex = New-Object System.Text.RegularExpressions.Regex($brokenPattern)
$match = $regex.Match($content)

if ($match.Success) {
    Write-Host "✅ تم العثور على نمط href الخاطئ" -ForegroundColor Green
    # الـ href الصحيح في JSX: href={`${AGENCY_DASH_URL}#agency_id=...`}
    $correct = 'href={`${AGENCY_DASH_URL}#agency_id=${result.agency_id}&email=${result.email}&password=${result.password}`}'
    $content = $regex.Replace($content, $correct, 1)
    Write-Host "✅ تم إصلاح href بنجاح" -ForegroundColor Green
} else {
    Write-Host "⚠️  لم يتم مطابقة النمط بالـ regex. بحث يدوي..." -ForegroundColor Yellow

    # طباعة المنطقة للبحث فيها
    $needle = 'فتح لوحة تحكم الوكالة'
    $idx = $content.IndexOf($needle)
    if ($idx -gt 0) {
        $lines = $content -split "`r?`n"
        $lineNum = ($content.Substring(0, $idx) -split "`r?`n").Count
        Write-Host "الأسطر حول الزر:" -ForegroundColor Cyan
        for ($i = [Math]::Max(0, $lineNum - 4); $i -lt [Math]::Min($lines.Count, $lineNum + 1); $i++) {
            Write-Host "  [$($i+1)] $($lines[$i])"
        }
        # إصلاح السطر الأول
        $startHref = $content.LastIndexOf('href=', $idx)
        $endHref = $content.IndexOf("}", $idx) + 1
        if ($startHref -ge 0 -and $endHref -gt $startHref) {
            $oldHref = $content.Substring($startHref, $endHref - $startHref)
            Write-Host "`nالـ href القديم: $oldHref" -ForegroundColor Red
            $correct = 'href={`${AGENCY_DASH_URL}#agency_id=${result.agency_id}&email=${result.email}&password=${result.password}`}'
            $content = $content.Remove($startHref, $endHref - $startHref).Insert($startHref, $correct)
            Write-Host "الـ href الجديد: $correct" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ لم يتم إيجاد زر 'فتح لوحة تحكم الوكالة' أصلاً!" -ForegroundColor Red
        exit 1
    }
}

[System.IO.File]::WriteAllText($agencyFile, $content, $utf8NoBom)
Write-Host "`n✅ تم حفظ الإصلاح" -ForegroundColor Green

# طباعة المنطقة بعد الإصلاح للتأكد
$lines2 = ([System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)) -split "`r?`n"
$idx2 = 0
for ($i = 0; $i -lt $lines2.Count; $i++) { if ($lines2[$i] -match "agency_id=`$\{result\.agency_id\}") { $idx2 = $i; break } }
if ($idx2 -gt 0) {
    Write-Host "`nالمنطقة بعد الإصلاح:" -ForegroundColor Cyan
    for ($i = [Math]::Max(0, $idx2 - 1); $i -lt [Math]::Min($lines2.Count, $idx2 + 4); $i++) {
        Write-Host "  [$($i+1)] $($lines2[$i])"
    }
}
exit 0
