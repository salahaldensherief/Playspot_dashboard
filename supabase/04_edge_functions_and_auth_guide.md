# دليل أمان الـ Edge Functions وإعدادات المصادقة (Supabase Auth & Functions Security)

يقدم هذا الدليل التوجيهات الخطوة بخطوة لتأمين **Edge Functions** وإعدادات **Supabase Auth** بناءً على نتائج الفحص الشامل.

---

## 1. تأمين الـ Edge Function (`send-fcm-notification`)

### المشكلة:
تعديل خيار `verify_jwt: false` يتيح لأي جهة استدعاء الدالة مباشرة عبر HTTP POST واستهلاك حصة إشعارات FCM الخاصة بمشروعك.

### خطوات الإصلاح:

#### الخيار 1: تفعيل تحقق الـ JWT (الموصى به)
1. في مجلد الـ Function المقتطع في السيرفر أو الـ repository الخاص بالـ Functions:
   أنشئ أو عدّل الملف `supabase/functions/send-fcm-notification/config.toml`:
   ```toml
   [functions.send-fcm-notification]
   verify_jwt = true
   ```
2. أعد رفع الدالة عبر Supabase CLI:
   ```bash
   supabase functions deploy send-fcm-notification
   ```

#### الخيار 2: استخدام رأس حماية داخلي (Internal Secret / HMAC)
إذا كانت الدالة تُستدعى بواسطة Trigger أو Webhook أو `pg_net` داخل قاعدة البيانات:
1. أنشئ متغير بيئة سري بداخل Supabase Edge Functions:
   ```bash
   supabase secrets set FCM_INTERNAL_SECRET="YOUR_SUPER_SECRET_KEY_HERE"
   ```
2. في كود الدالة (`index.ts`):
   ```typescript
   const authHeader = req.headers.get("X-Internal-Secret");
   const expectedSecret = Deno.env.get("FCM_INTERNAL_SECRET");

   if (!authHeader || authHeader !== expectedSecret) {
     return new Response(JSON.stringify({ error: "Unauthorized request" }), {
       status: 401,
       headers: { "Content-Type": "application/json" }
     });
   }
   ```

---

## 2. تعزيز أمان حسابات والمصادقة (Supabase Auth Hardening)

### أ. تفعيل منع كلمات المرور المسربة (Leaked Password Protection)
منع المستخدمين ومدراء النظام من اختيار كلمات مرور ظهرت سابقاً في التسريبات العالمية (HaveIBeenPwned API):
1. افتح **Supabase Dashboard**.
2. انتقل إلى **Authentication** ➔ **Providers** ➔ **Email**.
3. قم بتفعيل الخيار: **"Prevent the use of leaked passwords"**.

### ب. تفعيل التحقق متعدد العوامل (MFA) للحسابات الإدارية
1. من لوحة التحكّم: **Authentication** ➔ **MFA**.
2. فعّل خيار **App-based TOTP (Authenticator App)**.
3. ألزم كافة حسابات الأدوار (`super_admin`, `owner`, `manager`) بالتسجيل عبر TOTP عند الدخول.

---

## 3. تنظيف المؤشرات غير المستعملة (Unused Indexes Strategy)

المشروع يحتوي على **68 Index غير مستعمل حالياً**.
* **التوصية:** عدم حذف هذه المؤشرات جماعياً في الوقت الحالي لأن حجم البيانات صغير والمشروع في مرحلة بداية التشغيل.
* **الخطة التنفذية لاحقاً:**
  بعد مرور 30 يوماً من التشغيل الفعلي بكثافة، شغّل الاستعلام التالي لمعرفة المؤشرات غير المستعملة حقيقةً والتي تسبب بطئاً في الـ Writes:
  ```sql
  SELECT
      schemaname || '.' || relname AS table_name,
      indexrelname AS index_name,
      idx_scan AS number_of_scans,
      pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
  FROM pg_stat_user_indexes
  WHERE idx_scan = 0
    AND idxrelid NOT IN (
        SELECT conindid FROM pg_constraint WHERE contype IN ('p', 'u', 'f')
    )
  ORDER BY pg_relation_size(indexrelid) DESC;
  ```
