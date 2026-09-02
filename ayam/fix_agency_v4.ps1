
# ============================================================
# إصلاح شرط عرض التبويب فقط - نمط مرن جداً
# ============================================================

$agencyFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\pages\Agency.tsx"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$content = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)

Write-Host "البحث عن نمط عرض الشرط..." -ForegroundColor Yellow

# أولًا: طباعة جزء من الملف حول منطقة تبويب agencies لمعرفة النمط الفعلي
$lines = $content -split "`r?`n"
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "tab === .agencies.") {
        Write-Host "`nالأسطر المحيطة بشرط agencies:" -ForegroundColor Cyan
        $start = [Math]::Max(0, $i - 2)
        $end = [Math]::Min($lines.Count - 1, $i + 5)
        for ($j = $start; $j -le $end; $j++) {
            Write-Host "  [$j] $($lines[$j])"
        }
        break
    }
}

# محاولة 1: مطابقة مرنة جداً لأي نمط يشبه tab === 'agencies'
$pattern1 = "(tab\s*===\s*'agencies'\s*&&\s*<AgenciesTab\s*/>\s*)"
if ($content -match $pattern1) {
    Write-Host "`n✅ تم العثور على النمط باستخدام pattern1" -ForegroundColor Green
    $match = [regex]::Match($content, $pattern1)
    $insertAfter = $match.Index + $match.Length
    $newLine = "`r`n      {tab === 'open_requests' && <OpenRequestsTab />}"
    $content = $content.Insert($insertAfter, $newLine)
} else {
    # محاولة 2: بحث عن AgenciesTab ثم إضافة السطر بعده
    Write-Host "pattern1 فشل، محاولة pattern2..." -ForegroundColor Yellow
    $idx = $content.IndexOf("<AgenciesTab />")
    if ($idx -gt 0) {
        Write-Host "✅ تم العثور على <AgenciesTab /> عند الفهرس $idx" -ForegroundColor Green
        # البحث عن نهاية السطر بعد AgenciesTab
        $endOfLine = $content.IndexOf("}`n", $idx)
        if ($endOfLine -lt 0) { $endOfLine = $content.IndexOf("}`r`n", $idx) }
        if ($endOfLine -gt 0) {
            $insertAt = $endOfLine + 1
            $content = $content.Insert($insertAt, "`r`n      {tab === 'open_requests' && <OpenRequestsTab />}")
        } else {
            # فقط أضف بعد AgenciesTab مباشرة
            $content = $content.Insert($idx + "<AgenciesTab />".Length, "}`r`n      {tab === 'open_requests' && <OpenRequestsTab />")
        }
    } else {
        throw "لم يتم العثور على AgenciesTab في الملف!"
    }
}

# حفظ الملف
[System.IO.File]::WriteAllText($agencyFile, $content, $utf8NoBom)
Write-Host "`n✅ تم حفظ الملف" -ForegroundColor Green

# التحقق النهائي
$final = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)
$finalOk = ($final -match "tab === \x27open_requests\x27")
Write-Host "`n========================================"
if ($finalOk) {
    Write-Host "🎉 تم إصلاح كل شيء بنجاح!" -ForegroundColor Green
    Write-Host "========================================"
    exit 0
} else {
    Write-Host "❌ لا يزال الشرط مفقوداً" -ForegroundColor Red
    Write-Host "========================================"
    # طباعة الأسطر حول المنطقة للتصحيح
    $lines2 = $final -split "`r?`n"
    for ($i = 0; $i -lt $lines2.Count; $i++) {
        if ($lines2[$i] -match "AgenciesTab|OpenRequestsTab") {
            Write-Host "  [$i] $($lines2[$i])"
        }
    }
    exit 1
}
