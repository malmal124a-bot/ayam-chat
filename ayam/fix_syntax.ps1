
$agencyFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\pages\Agency.tsx"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$content = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)

Write-Host "إصلاح الخطأ التركيبي..." -ForegroundColor Yellow

# إصلاح النمط الخاطئ:
# {tab === 'agencies' && <AgenciesTab />
# {tab === 'open_requests' && <OpenRequestsTab />}}
# إلى النمط الصحيح:
# {tab === 'agencies' && <AgenciesTab />}
# {tab === 'open_requests' && <OpenRequestsTab />}

$brokenPattern = "\{tab === 'agencies' && <AgenciesTab />\s*\r?\n\s*\{tab === 'open_requests' && <OpenRequestsTab />\}\}"
$fixed = @"
{tab === 'agencies' && <AgenciesTab />}
      {tab === 'open_requests' && <OpenRequestsTab />}
"@

$newContent = [regex]::Replace($content, $brokenPattern, $fixed)

if ($newContent -eq $content) {
    Write-Host "⚠️  لم يتم العثور على النمط الخاطئ، طباعة الأسطر المحيطة..." -ForegroundColor Yellow
    $lines = $content -split "`r?`n"
    for ($i = 70; $i -lt 85; $i++) {
        Write-Host "  [$($i+1)] $($lines[$i])"
    }
    exit 1
}

[System.IO.File]::WriteAllText($agencyFile, $newContent, $utf8NoBom)
Write-Host "✅ تم إصلاح الخطأ التركيبي" -ForegroundColor Green

# طباعة الأسطر بعد الإصلاح للتحقق
$lines = ([System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)) -split "`r?`n"
Write-Host "`nالأسطر بعد الإصلاح:" -ForegroundColor Cyan
for ($i = 70; $i -lt 85; $i++) {
    Write-Host "  [$($i+1)] $($lines[$i])"
}
exit 0
