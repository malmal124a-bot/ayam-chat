
# إضافة زر فتح لوحة الوكالة في بطاقة النتيجة (تصحيح النمط)
$agencyFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\pages\Agency.tsx"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$content = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)
$searchFrom = $content.IndexOf("function OpenRequestsTab()")

Write-Host "بحث عن السطر الذي يحتوي على كلمة المرور..." -ForegroundColor Yellow

# النمط الفعلي من الملف (كما هو مطبوع في الإخراج):
# {result.password && <p>كلمة المرور: <span className="text-white font-mono">{result.password}</span></p>}
$actualPattern = '>{result.password}</span></p>}'
$idx = $content.IndexOf($actualPattern, $searchFrom)
if ($idx -lt 0) {
    Write-Host "⚠️  لم يتم العثور بـ '$actualPattern'، جرب نمطاً آخر..." -ForegroundColor Yellow
    # نمط أكثر مرونة
    $idx = $content.IndexOf('{result.password}</span>', $searchFrom)
    if ($idx -gt 0) {
        Write-Host "✅ تم العثور على نمط فرعي: '{result.password}</span>'" -ForegroundColor Green
    } else {
        # طباعة الأسطر حول بطاقة النتيجة في OpenRequestsTab
        $lines = $content -split "`r?`n"
        $boxIdx = $content.IndexOf("bg-emerald-500/10 border-emerald-500/30", $searchFrom)
        $lineNum = ($content.Substring(0, $boxIdx) -split "`r?`n").Count
        Write-Host "حول منطقة بطاقة النتيجة:" -ForegroundColor Cyan
        for ($i = [Math]::Max(0, $lineNum - 2); $i -lt [Math]::Min($lines.Count, $lineNum + 18); $i++) {
            Write-Host "  [$($i+1)] $($lines[$i])"
        }
        exit 1
    }
}

# تحقق مما إذا كان هناك زر فتح لوحة مضاف بالفعل؟
$buttonCheck = $content.IndexOf("فتح لوحة تحكم الوكالة", $searchFrom)
if ($buttonCheck -gt 0 -and $buttonCheck -lt ($idx + 800)) {
    Write-Host "ℹ️  زر فتح لوحة الوكالة موجود مسبقاً" -ForegroundColor Cyan
    exit 0
}

# مكان الإدخال: بعد إغلاق </> الخاص ببيانات الوكالة (أو بعد نهاية السطر الحالي الذي يحتوي على نتيجة كلمة المرور)
# من المطبوع:
# [1480] {result.agency_id && (
# [1481]   <>
# [1482]     <p>رقم الوكالة ...
# [1483]     {result.email && ...
# [1484]     {result.password && <p>...{result.password}</span></p>}
# [1485]   </>
# [1486] )}
# نضيف الزر بعد السطر [1485] (قبل </>) أو بعد [1486] قبل إغلاق space-y-1

# أسهل طريقة: نبحث عن أول `</>` بعد المؤشر $idx (إغلاق Fragment)، ثم نضيف الزر قبله
$closeFrag = $content.IndexOf("</>", $idx)
if ($closeFrag -gt 0 -and $closeFrag -lt $idx + 400) {
    Write-Host "✅ تم العثور على إغلاق Fragment </> عند $closeFrag" -ForegroundColor Green
    $insertAt = $closeFrag
    $newButton = @"

                 <a href={`$AGENCY_DASH_URL#agency_id=`${result.agency_id}&email=`${result.email}&password=`${result.password}`} target="_blank" rel="noreferrer"
                   className="mt-2 inline-block text-xs bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-1.5 rounded-lg font-semibold">
                   فتح لوحة تحكم الوكالة ↗
                 </a>
"@
    # تصحيح الـ escaping في السابق: السطر يجب أن يكون بالشكل: href={`$AGENCY_DASH_URL#...`}
    # (بدون علامات اقتباس مفردة إضافية)
    $newButton = $newButton.Replace('"`$AGENCY_DASH_URL#', '`$AGENCY_DASH_URL#').Replace('password}`}"', 'password}`}')

    Write-Host "`nالزر الذي سيضاف:" -ForegroundColor Cyan
    Write-Host $newButton

    $content = $content.Insert($insertAt, $newButton)
    Write-Host "`n✅ تم إضافة الزر بنجاح قبل إغلاق </>" -ForegroundColor Green

} else {
    Write-Host "⚠️  لم يتم إيجاد </>، نضيف بعد إغلاق الفقرة الحالية..." -ForegroundColor Yellow
    $closeP = $content.IndexOf("</p>", $idx)
    if ($closeP -gt 0) {
        $insertAt = $closeP + 4
        $newButton = @"

                 <a href={`$AGENCY_DASH_URL#agency_id=`${result.agency_id}&email=`${result.email}&password=`${result.password}`} target="_blank" rel="noreferrer"
                   className="mt-2 inline-block text-xs bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-1.5 rounded-lg font-semibold">
                   فتح لوحة تحكم الوكالة ↗
                 </a>
"@
        $content = $content.Insert($insertAt, $newButton)
        Write-Host "✅ تم إضافة الزر بعد إغلاق <p>" -ForegroundColor Green
    } else {
        Write-Host "❌ تعذر تحديد موقع الإدراج" -ForegroundColor Red
        exit 1
    }
}

[System.IO.File]::WriteAllText($agencyFile, $content, $utf8NoBom)
Write-Host "✅ تم حفظ التعديلات" -ForegroundColor Green
exit 0
