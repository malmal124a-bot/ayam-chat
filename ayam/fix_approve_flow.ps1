
# ============================================================
# الإصلاح الكامل لدوال الموافقة على طلبات فتح الوكالات
# ============================================================

$dbFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\lib\db.ts"
$agencyFile = "c:\Users\m3290\Downloads\ayam_chat\ayam_chat\admincore-dashboard\src\pages\Agency.tsx"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "إصلاح db.ts: approveAgencyOpenRequest" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ============================================================
# الإصلاح 1: db.ts approveAgencyOpenRequest
# ============================================================
$dbContent = [System.IO.File]::ReadAllText($dbFile, $utf8NoBom)

# النمط القديم للدالة (مع الـ regex مرن لـ whitespaces  ومحارف الإرجاع)
$oldApprove = @'
export async function approveAgencyOpenRequest\(requestId: string\): Promise<\{ ok: boolean; error\?: string \}> \{
  try \{
    const BACKEND_URL = 'https://backend-seven-brown-72\.vercel\.app';
    let token = 'ayam-admin';
    try \{
      const raw = localStorage\.getItem\('supabase_admin_config'\);
      if \(raw\) \{ const cfg = JSON\.parse\(raw\); const key = \(cfg\.serviceRoleKey \|\| ''\)\.trim\(\); if \(key\) token = key; \}
    \} catch \{\}
    const resp = await fetch\(\`\$\{BACKEND_URL\}/api/admin/open-request/approve\`, \{
      method: 'POST',
      headers: \{ 'Content-Type': 'application/json', 'Authorization': \`Bearer \$\{token\}\` \},
      body: JSON\.stringify\(\{ request_id: requestId \}\),
    \}\);
    const data = await resp\.json\(\);
    return data\.ok === false \? \{ ok: false, error: data\.error \|\| 'فشل الموافقة' \} : \{ ok: true \};
  \} catch \(e: any\) \{ return \{ ok: false, error: e\.message \}; \}
\}
'@

$newApprove = @'
export async function approveAgencyOpenRequest(requestId: string): Promise<{ ok: boolean; error?: string; agency_id?: string; email?: string; password?: string; dashboard_url?: string }> {
  try {
    const BACKEND_URL = 'https://backend-seven-brown-72.vercel.app';
    let token = 'ayam-admin';
    try {
      const raw = localStorage.getItem('supabase_admin_config');
      if (raw) { const cfg = JSON.parse(raw); const key = (cfg.serviceRoleKey || '').trim(); if (key) token = key; }
    } catch {}
    const resp = await fetch(`${BACKEND_URL}/api/admin/open-request/approve`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ request_id: requestId }),
    });
    const data = await resp.json();
    if (data.ok === false) {
      return { ok: false, error: data.error || 'فشل الموافقة' };
    }
    return {
      ok: true,
      agency_id: data.agency_id,
      email: data.dashboard_email || data.email,
      password: data.dashboard_password || data.password,
      dashboard_url: data.dashboard_url,
    };
  } catch (e: any) { return { ok: false, error: e.message }; }
}
'@

$regexApprove = New-Object System.Text.RegularExpressions.Regex($oldApprove, [System.Text.RegularExpressions.RegexOptions]::Multiline)
$dbMatch = $regexApprove.Match($dbContent)
if ($dbMatch.Success) {
    $dbContent = $regexApprove.Replace($dbContent, $newApprove, 1)
    Write-Host "✅ تم إصلاح دالة approveAgencyOpenRequest بنجاح" -ForegroundColor Green
} else {
    Write-Host "⚠️  فشل مطابقة النمط باستخدام regex، محاولة باستخدام المحددات اليدوية..." -ForegroundColor Yellow

    # بداية ونهاية الدالة
    $fnStart = $dbContent.IndexOf("export async function approveAgencyOpenRequest")
    $fnEnd = $dbContent.IndexOf("export async function rejectAgencyOpenRequest")
    if ($fnStart -ge 0 -and $fnEnd -gt $fnStart) {
        $before = $dbContent.Substring(0, $fnStart)
        $after = $dbContent.Substring($fnEnd)
        $dbContent = $before + $newApprove + "`r`n`r`n" + $after
        Write-Host "✅ تم إصلاح الدالة باستخدام المحددات اليدوية" -ForegroundColor Green
    } else {
        throw "❌ لم يتم تحديد موقع الدالة في db.ts"
    }
}

# حفظ db.ts
[System.IO.File]::WriteAllText($dbFile, $dbContent, $utf8NoBom)
Write-Host "✅ تم حفظ db.ts" -ForegroundColor Green

# ============================================================
# الإصلاح 2: Agency.tsx - handleApprove في OpenRequestsTab
# ============================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "إصلاح Agency.tsx: handleApprove في OpenRequestsTab" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$agencyContent = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)

# أولاً: طباعة الدالة الحالية handleApprove الموجودة داخل OpenRequestsTab (تستخدم approveAgencyOpenRequest)
Write-Host "`nالبحث عن handleApprove الصحيحة داخل OpenRequestsTab..." -ForegroundColor Yellow

$searchFrom = $agencyContent.IndexOf("function OpenRequestsTab()")
if ($searchFrom -lt 0) { throw "لم يتم إيجاد OpenRequestsTab" }

# البحث عن: const handleApprove = async (id: string) => { ... approveAgencyOpenRequest ... };
$handlerStart = $agencyContent.IndexOf("const handleApprove = async", $searchFrom)
if ($handlerStart -lt 0) { throw "لم يتم إيجاد handleApprove في OpenRequestsTab" }
Write-Host "✅ بداية handleApprove عند الفهرس: $handlerStart" -ForegroundColor Green

# طباعة محتوى الدالة الحالية للمرجع قبل الإصلاح
$lines = $agencyContent -split "`r?`n"
$currentLine = ($agencyContent.Substring(0, $handlerStart) -split "`r?`n").Count
Write-Host "`nمحتوى handleApprove الحالي:" -ForegroundColor Cyan
for ($i = [Math]::Max(0, $currentLine - 1); $i -lt [Math]::Min($lines.Count, $currentLine + 18); $i++) {
    Write-Host "  [$($i+1)] $($lines[$i])"
}

# الإصلاح: استبدال نص الدالة بالكامل
# نمط الدالة القديمة: (من handleApprove = async حتى نهاية الأقواس)
# نستبدلها بالصحيحة التي تستخرج البيانات وتعرضها

$oldHandlerRegex = "(const handleApprove = async \(id: string\) => \{[\s\S]*?approveAgencyOpenRequest\(id\);[\s\S]*?load\(\);\s*\};)"

$handlerRegex = New-Object System.Text.RegularExpressions.Regex($oldHandlerRegex)
$match2 = $handlerRegex.Match($agencyContent, $searchFrom)

if ($match2.Success) {
    Write-Host "`n✅ تم مطابقة نمط handleApprove القديم (الطول: $($match2.Length))" -ForegroundColor Green
} else {
    Write-Host "⚠️  فشل regex النمط العام، سنستخدم محددات أقواس يدوية..." -ForegroundColor Yellow
}

# الدالة الجديدة الصحيحة:
$newHandler = @'
const handleApprove = async (id: string) => {
    if (!confirm('هل أنت متأكد من الموافقة على فتح هذه الوكالة؟ سيتم إنشاء حساب لوحة التحكم تلقائياً.')) return;
    setResult(null);
    // إزالة الطلب محلياً من القائمة فوراً لعدم ظهوره أثناء انتظار الرد
    setRequests(prev => prev.filter(r => r.id !== id));
    const res = await approveAgencyOpenRequest(id);
    if (res.ok) {
      setResult({
        ok: true,
        msg: '🎉 تمت الموافقة على فتح الوكالة بنجاح! أرسل هذه البيانات للمستخدم:',
        agency_id: res.agency_id,
        email: res.email,
        password: res.password,
      });
    } else {
      // إعادة إضافة الطلب في حال فشل العملية
      load();
      setResult({ ok: false, msg: '❌ فشل الموافقة: ' + (res.error || 'خطأ غير معروف') });
    }
  };
'@

if ($match2.Success) {
    $agencyContent = $agencyContent.Remove($match2.Index, $match2.Length).Insert($match2.Index, $newHandler)
    Write-Host "✅ تم استبدال handleApprove بنجاح (regex)" -ForegroundColor Green
} else {
    # محاولة يدوية: إقفال الأقواس
    $braceStart = $agencyContent.IndexOf("{", $handlerStart)
    $depth = 0
    $endIdx = $braceStart
    for ($i = $braceStart; $i -lt $agencyContent.Length; $i++) {
        $ch = $agencyContent[$i]
        if ($ch -eq '{') { $depth++ }
        elseif ($ch -eq '}') {
            $depth--
            if ($depth -eq 0) {
                $endIdx = $i + 1
                # الآن نبحث عن الـ ';' القادمة بعدها
                $semiIdx = $agencyContent.IndexOf(';', $endIdx)
                if ($semiIdx -ge 0 -and $semiIdx -lt $endIdx + 5) { $endIdx = $semiIdx + 1 }
                break
            }
        }
    }
    Write-Host "✅ النطاق اليدوي: من $handlerStart إلى $endIdx" -ForegroundColor Green
    $agencyContent = $agencyContent.Remove($handlerStart, $endIdx - $handlerStart).Insert($handlerStart, $newHandler)
}

# حفظ Agency.tsx
[System.IO.File]::WriteAllText($agencyFile, $agencyContent, $utf8NoBom)
Write-Host "✅ تم حفظ Agency.tsx" -ForegroundColor Green

# ============================================================
# الإصلاح 3: عرض بيانات الاعتماد في البطاقة العلوية (لو كانت ناقصة)
# ============================================================
# في الواجهة الحالية، بطاقة result تعرض agency_id/email/password بالفعل،
# لكننا نتأكد من أن النمط يحتويها (طباعة لأغراض التأكد فقط)

$agencyContent2 = [System.IO.File]::ReadAllText($agencyFile, $utf8NoBom)
$credIdx = $agencyContent2.IndexOf("agency_id && (")
if ($credIdx -gt 0) { Write-Host "`n✅ منطق عرض بيانات الوكالة موجود في بطاقة result" -ForegroundColor Green }
else { Write-Host "`n⚠️  بطاقة result لم يتم إيجاد عرض agency_id، نتأكد..." -ForegroundColor Yellow }

# طباعة أول 40 سطر من نتيجة البطاقة للتصحيح
$resultBoxIdx = $agencyContent2.IndexOf("result && (")
if ($resultBoxIdx -lt 0) { $resultBoxIdx = $agencyContent2.IndexOf("{result") }
if ($resultBoxIdx -gt 0) {
    $lines2 = $agencyContent2 -split "`r?`n"
    $resLine = ($agencyContent2.Substring(0, $resultBoxIdx) -split "`r?`n").Count
    Write-Host "`nبطاقة النتيجة تبدأ من السطر: $resLine" -ForegroundColor Cyan
    for ($i = [Math]::Max(0, $resLine - 1); $i -lt [Math]::Min($lines2.Count, $resLine + 22); $i++) {
        Write-Host "  [$($i+1)] $($lines2[$i])"
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "تم تطبيق جميع الإصلاحات! جاري البناء..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
exit 0
