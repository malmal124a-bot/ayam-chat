# Ayam Chat Backend (Railway)

باك إند بسيط (Express) مرتبط بـ Supabase — جاهز للرفع على Railway من GitHub.

## الـ Endpoints

| Method | Path | الوصف |
|--------|------|-------|
| GET | `/health` | فحص السيرفر |
| GET | `/api/users` | كل المستخدمين |
| GET | `/api/users/:id` | مستخدم بـ auth_uid أو numeric_id |
| POST | `/api/users` | إنشاء مستخدم |
| PATCH | `/api/users/:id` | تعديل مستخدم |
| GET | `/api/agencies` | كل الوكالات |
| GET | `/api/agencies/:id` | وكالة معينة |
| POST | `/api/agencies` | إنشاء وكالة |
| PATCH | `/api/agencies/:id` | تعديل وكالة |
| GET | `/api/medals` | الميداليات |
| GET | `/api/rooms` | كل الغرف |
| GET | `/api/rooms/:id` | غرفة معينة |
| PATCH | `/api/rooms/:id` | تعديل غرفة |

## تشغيل محلي

```bash
cd backend
cp .env.example .env    # حط الـ service role key فيه
npm install
npm start
```

السيرفر هيشتغل على `http://localhost:3000`.

## الرفع على Railway

1. اعمل repository على GitHub وارفع مجلد المشروع (أو backend لوحده).
2. افتح `https://railway.com/new/github` واختار الـ repository.
3. Railway هيشتغل تلقائياً (ملف `railway.json` جاهز).
4. في لوحة المشروع: **Variables** أضف:
   - `SUPABASE_URL` = `https://dhabrfnfirhhcrdbvzdi.supabase.co`
   - `SUPABASE_SERVICE_ROLE_KEY` = المفتاح من Supabase (Project Settings > API > service_role)
5. بعد الـ deploy، اشتغل السيرفر وجرّب `https://<اسم-المشروع>.up.railway.app/health`.

## بعد النشر

- نسخ الرابط الجديد (`https://<اسم-المشروع>.up.railway.app/api`) وحطه في:
  `lib/core/config.dart` > `AppConfig.baseUrl`

## ملاحظات أمان

- الـ `service_role` key له صلاحيات كاملة — متحطهوش أبداً في تطبيق الموبايل، خليه في السيرفر فقط.
- متحطش `.env` في الـ repository.
