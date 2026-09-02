
$agencyFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\pages\Agency.tsx"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$content = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)

Write-Host "إصلاح أخطاء className في مكون OpenRequestsTab..." -ForegroundColor Yellow

# الخطأ 1: <div className={p-3 rounded-lg text-xs border }>
# يجب أن يكون مع template literal وشرط result.ok
$broken1 = 'className=\{p-3 rounded-lg text-xs border \}'
$fixed1 = 'className={`p-3 rounded-lg text-xs border ${result.ok ? ''bg-emerald-500/10 border-emerald-500/30 text-emerald-400'' : ''bg-rose-500/10 border-rose-500/30 text-rose-400''}`}'

# محاولة استبدال أكثر مرونة - نبحث عن النمط العام ونستبدله كاملاً
# أولاً: طباعة المنطقة الخاطئة
$lines = $content -split "`r?`n"
Write-Host "`nالأسطر حول 1463:" -ForegroundColor Cyan
for ($i = 1458; $i -lt 1475; $i++) {
    if ($i -lt $lines.Count) { Write-Host "  [$($i+1)] $($lines[$i])" }
}

# إصلاح شامل لجميع classNames الخاطئة في OpenRequestsTab باستخدام regex أكثر ذكاءً
# نمط 1: className={... بدون اقتباس
$content = [regex]::Replace($content, "className=\{p-3 rounded-lg text-xs border \}", 'className={$(`p-3 rounded-lg text-xs border ${result.ok ? `"bg-emerald-500/10 border-emerald-500/30 text-emerald-400"` : `"bg-rose-500/10 border-rose-500/30 text-rose-400"`}`)}')

# حفظ وطباعة المنطقة بعد الإصلاح
[System.IO.File]::WriteAllText($agencyFile, $content, $utf8NoBom)
Write-Host "`nبعد الإصلاح الأولي:" -ForegroundColor Green
$lines2 = ([System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)) -split "`r?`n"
for ($i = 1458; $i -lt 1475; $i++) {
    if ($i -lt $lines2.Count) { Write-Host "  [$($i+1)] $($lines2[$i])" }
}
exit 0
