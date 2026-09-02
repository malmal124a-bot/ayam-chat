
# ============================================================
# التحسينات النهائية:
# 1. handleRejectConfirm: إزالة محلية بدلاً من load()
# 2. تحسين بطاقة النتيجة في OpenRequestsTab لإضافة زر لوحة التحكم
# ============================================================

$agencyFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\pages\Agency.tsx"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$content = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "التحسينات النهائية على OpenRequestsTab" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ============================================================
# 1. إصلاح handleRejectConfirm ليستخدم إزالة محلية بدلاً من load()
# ============================================================
Write-Host "`n[1/2] إصلاح تدفق الرفض (reject)..." -ForegroundColor Yellow

$searchFrom = $content.IndexOf("function OpenRequestsTab()")
$rejectStart = $content.IndexOf("const handleRejectConfirm = async", $searchFrom)

if ($rejectStart -ge 0) {
    # مطابقة نمط handleRejectConfirm الحالي
    $rejectPattern = "(const handleRejectConfirm = async\(\) => \{[\s\S]*?rejectAgencyOpenRequest\(rejectingId, rejectNote\);[\s\S]*?load\(\);\s*\};)"
    $regex = New-Object System.Text.RegularExpressions.Regex($rejectPattern)
    $match = $regex.Match($content, $searchFrom)

    $newRejectHandler = @'
const handleRejectConfirm = async () => {
    if (!rejectingId) return;
    // إزالة الطلب محلياً أولاً
    const currentRejectingId = rejectingId;
    setRequests(prev => prev.filter(r => r.id !== currentRejectingId));
    setRejectingId(null);
    const res = await rejectAgencyOpenRequest(currentRejectingId, rejectNote);
    if (res.ok) {
      setResult({ ok: true, msg: '✅ تم رفض الطلب بنجاح' });
    } else {
      // فشل: نعيد تحميل القائمة لأصل الحالة
      load();
      setResult({ ok: false, msg: '❌ فشل الرفض: ' + (res.error || 'خطأ غير معروف') });
    }
    setRejectNote('');
  };
'@

    if ($match.Success) {
        $content = $content.Remove($match.Index, $match.Length).Insert($match.Index, $newRejectHandler)
        Write-Host "✅ تم استبدال handleRejectConfirm (regex)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  regex فشل، استخدام المحددات اليدوية للأقواس..." -ForegroundColor Yellow
        $braceStart = $content.IndexOf("{", $rejectStart)
        $depth = 0
        $endIdx = $braceStart
        for ($i = $braceStart; $i -lt $content.Length; $i++) {
            $ch = $content[$i]
            if ($ch -eq '{') { $depth++ }
            elseif ($ch -eq '}') {
                $depth--
                if ($depth -eq 0) {
                    $endIdx = $i + 1
                    $semi = $content.IndexOf(';', $endIdx)
                    if ($semi -ge 0 -and $semi -lt $endIdx + 5) { $endIdx = $semi + 1 }
                    break
                }
            }
        }
        $content = $content.Remove($rejectStart, $endIdx - $rejectStart).Insert($rejectStart, $newRejectHandler)
        Write-Host "✅ تم استبدال handleRejectConfirm (يدوي)" -ForegroundColor Green
    }
} else {
    Write-Host "❌ لم يتم إيجاد handleRejectConfirm" -ForegroundColor Red
    exit 1
}

# ============================================================
# 2. تحسين بطاقة النتيجة في OpenRequestsTab لإضافة زر فتح لوحة الوكالة
# ============================================================
Write-Host "`n[2/2] تحسين بطاقة النتيجة (Result Box)..." -ForegroundColor Yellow

# بطاقة النتيجة الحالية في OpenRequestsTab تحتوي على:
# <div className={`p-3 rounded-lg text-xs border ${result.ok ? ... }`}>
# يليها عرض رقم الوكالة والبريد وكلمة المرور.
# نريد تحديثها لتشمل زر "فتح لوحة تحكم الوكالة" مثل AgenciesTab

# البحث عن نمط بطاقة النتيجة داخل OpenRequestsTab (بما يحتوي على result.ok ? ... bg-emerald : bg-rose)
# نستخدم نمطاً فريداً: يحتوي على النص 'تمت الموافقة على فتح الوكالة'
$oldBoxPattern = "(\{result && \(\s*<div className=\{`p-3 rounded-lg text-xs border \$\{result\.ok \? '[^']*' : '[^']*'\}`\}>\s*<div className=""space-y-1"">\s*<p className=""font-semibold"">\{result\.msg\}</p>\s*\{result\.agency_id && \("

$boxRegex = New-Object System.Text.RegularExpressions.Regex($oldBoxPattern)
$match2 = $boxRegex.Match($content)

if ($match2.Success) {
    Write-Host "✅ تم إيجاد بطاقة النتيجة القديمة" -ForegroundColor Green
} else {
    # طباعة الجزء للبحث فيه يدويًا
    Write-Host "⚠️  فشل regex البطاقة، البحث اليدوي..." -ForegroundColor Yellow
    $boxIdx = $content.IndexOf("result.msg", $searchFrom)
    if ($boxIdx -ge 0) {
        $lines = $content -split "`r?`n"
        $lineNum = ($content.Substring(0, $boxIdx) -split "`r?`n").Count
        Write-Host " موقع 'result.msg' في السطر: $lineNum" -ForegroundColor Cyan
        for ($i = [Math]::Max(0, $lineNum - 5); $i -lt [Math]::Min($lines.Count, $lineNum + 20); $i++) {
            Write-Host "  [$($i+1)] $($lines[$i])"
        }
    }
}

# بدلاً من مطابقة نص دقيق للـ className الذي يمكن أن يتغير،
# نبحث عن الموضع مباشرة بعد {result.password}</p> و قبل الإغلاق الأول للـ </div> داخل بطاقة النتيجة
# ثم نضيف الزر قبله

$passwordIdx = $content.IndexOf("{result.password}</p>", $searchFrom)
if ($passwordIdx -gt 0) {
    Write-Host "✅ تم العثور على {result.password}</p> عند الفهرس $passwordIdx" -ForegroundColor Green
    # بعد هذا السطر: إضافة الزر (مع التحقق أنه لا يوجد زر مضاف مسبقاً)
    $nextClosingDiv = $content.IndexOf("</div>", $passwordIdx)
    $nextButton = $content.IndexOf("فتح لوحة تحكم الوكالة", $passwordIdx, 500)

    if ($nextButton -lt 0 -or $nextButton -gt $nextClosingDiv + 200) {
        # إضافة الزر بعد كلمة المرور مباشرة
        $insertAt = $passwordIdx + "{result.password}</p>".Length
        $buttonCode = @"

              <a href={`${'$AGENCY_DASH_URL'}#agency_id=${'$'}{result.agency_id}&email=${'$'}{result.email}&password=${'$'}{result.password}`} target="_blank" rel="noreferrer"
                className="mt-2 inline-block text-xs bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-1.5 rounded-lg font-semibold">
                فتح لوحة تحكم الوكالة ↗
              </a>
"@
        # إزالة الـ escaping الزائد
        $buttonCode = $buttonCode -replace [regex]::Escape("`${'$AGENCY_DASH_URL'}"), '$AGENCY_DASH_URL'
        $buttonCode = $buttonCode -replace [regex]::Escape("${'$'}{result.agency_id}"), '${result.agency_id}'
        $buttonCode = $buttonCode -replace [regex]::Escape("${'$'}{result.email}"), '${result.email}'
        $buttonCode = $buttonCode -replace [regex]::Escape("${'$'}{result.password}"), '${result.password}'

        $content = $content.Insert($insertAt, $buttonCode)
        Write-Host "✅ تم إضافة زر 'فتح لوحة تحكم الوكالة' بنجاح" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  زر فتح لوحة الوكالة موجود مسبقاً، يتم التخطي" -ForegroundColor Cyan
    }
} else {
    Write-Host "❌ لم يتم إيجاد {result.password}</p>" -ForegroundColor Red
}

# حفظ الملف
[System.IO.File]::WriteAllText($agencyFile, $content, $utf8NoBom)
Write-Host "`n✅ تم حفظ Agency.tsx بنجاح" -ForegroundColor Green

exit 0
