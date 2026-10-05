# تقرير مراجعة وإصلاحات Backend PlaySpot (2026-10-05)

تم فحص وتأكيد واختبار كافة بنود خطة مراجعة وإصلاح الـ Backend الخاصة بمشروع **PlaySpot** على قاعدة بيانات Supabase الحية (`tgpdexoitemmpruepgyt`) ومستودع الداشبورد [`salahaldensherief/Playspot_dashboard`](https://github.com/salahaldensherief/Playspot_dashboard).

جميع الإصلاحات طُبقت رسميًا كـ Database Migrations مسجلة في جدول `supabase_migrations.schema_migrations` على Supabase، ومحفوظة بملفات مستقلة في مجلد `supabase/migrations/` ومرفوعة بـ Commits مستقلة على فرع `dev`.

---

## ملخص البنود والإصلاحات المنفذة

### 1. الكوبون في فلو الكاشير/الداشبورد قابل لإعادة الاستخدام من غير حد (عالي - تم الإصلاح ✅)
- **المشكلة**: الكوبون المستخدم في الداشبورد كان يتم خصمه في الحجز دون استهلاكه في `user_vouchers`، فيبقى بحالة `active` وقابل للاستخدام المتكرر.
- **الإصلاح**:
  1. إضافة عمود `applied_voucher_code text` لجدول `public.bookings`.
  2. تحديث `apply_booking_discount` لتسجيل `applied_voucher_code` واختيار السبب المناسب تلقائيًا.
  3. تحديث `complete_booking_payment` ليقوم آليًا وضمن الـ Transaction نفسها باستهلاك الكوبون وتحويل حالته إلى `used` وربطه بالـ `used_booking_id`.
- **Migration**: `20261005123000_consume_voucher_in_payment_completion.sql`
- **Commit**: [`9eff9aa`](https://github.com/salahaldensherief/Playspot_dashboard/commit/9eff9aa)
- **نتيجة الاختبار**: نجاح عزل واختبار فلو استهلاك الكوبون في `complete_booking_payment` وتحوله إلى `used`.

---

### 2. تمديد الجلسة بسعر مخصص يتأثر بـ Trigger احتساب السعر (عالي - تم الإصلاح ✅)
- **المشكلة**: عند استدعاء `approve_booking_extension` بسعر تفاوضي مخصص `p_additional_cost`، كان الـ Trigger `trg_validate_and_clamp_booking_price` يعيد حساب `total_price` من الصفر بالسعر القياسي للغرفة متجاهلًا السعر المخصص المسجل في المدفوعات والشيفت.
- **الإصلاح**:
  1. تعديل دالة الـ Trigger `fn_validate_and_clamp_booking_price` لتدعم فحص المتغير الجلسي `app.skip_price_clamp`.
  2. تحديث `approve_booking_extension` لتقوم بتعيين المتغير `PERFORM set_config('app.skip_price_clamp', 'true', true);` قبل تحديث الحجز للحفاظ على السعر المخصص المتفق عليه.
- **Migration**: `20261005123500_support_custom_cost_extension_approval.sql`
- **Commit**: [`d853646`](https://github.com/salahaldensherief/Playspot_dashboard/commit/d853646)
- **نتيجة الاختبار**: تمديد حجز بسعر مخصص 120 ج.م بدلاً من السعر القياسي واحتفاظ الحجز بالقيمة الصحيحة (200 ج.م) في قاعدة البيانات دون مساس من الـ Trigger.

---

### 3. وجود دالتين لإغلاق الوردية `close_shift` و `close_lounge_shift` (منخفض - فحص وتوثيق ✅)
- **الواقع البرمجي**:
  - `close_shift(p_shift_id, p_actual_cash, p_notes)`: تغلق وردية محددة بمعرف الوردية `p_shift_id`.
  - `close_lounge_shift(p_lounge_id, p_actual_cash_counted, p_notes)`: تستخدمها الداشبورد في شاشة الصالات (`toggleLoungeOpenStatus`) لإغلاق الوردية المفتوحة للصالة تلقائيًا عند إغلاق الصالة دون معرفة الـ `shift_id` مسبقًا.
- **التوصية وعقد التكامل**: الدالتان لهما غرضان مختلفان (واحدة بمعرف الوردية والأخرى بالصالة كـ fallback إداري). تم توثيق دورهما ولا ينصح بحذف أي منهما منعاً لكسر toggle تشغيل الصالة.

---

### 4. حماية كلمة المرور المسروقة (Leaked Password Protection) (منخفض - مقيد من المزود ℹ️)
- **النتيجة**: تم التحقق عبر Supabase Management API. أرجعت المنصة:
  > `"Configuring leaked password protection via HaveIBeenPwned.org is available on Pro Plans and up."`
- **المطلوب**: ترقية المشروع إلى Pro Plan من لوحة تحكم Supabase، ثم تفعيل خيار HIBP من **Authentication > Security**.

---

### 5. تكرار سياسات RLS على عدة جداول (منخفض - تم الإصلاح ✅)
- **المشكلة**: وجود سياسات `PERMISSIVE` مكررة على جداول متعددة مما يسبب أعباء تقييم مكررة أثناء تنفيذ الاستعلامات.
- **الإصلاح**: دمج وحذف السياسات المكررة على الجداول الآمنة:
  - `promotions`: حذف `allow_read_clean_promotions` والإبقاء على `promotions_select_policy`.
  - `loyalty_levels`: حذف `loyalty_levels_read` والإبقاء على `loyalty_levels_select`.
  - `points_transactions`: حذف `Users can view their own points history` لتغطيتها بالكامل بـ `points_transactions_select`.
  - `referrals`: حذف `Users can view referrals they made` لتغطيتها بـ `referrals_select`.
  - `canteen_orders`: حذف `Staff can update lounge canteen orders` القديمة.
  - `service_calls`: حذف السياسات المكررة وتوحيدها.
- **Migration**: `20261005122500_consolidate_redundant_rls_policies.sql`
- **Commit**: [`d34aa97`](https://github.com/salahaldensherief/Playspot_dashboard/commit/d34aa97)
- **نتيجة الاختبار**: التحقق من خلو الجداول المذكورة من أي تكرار لسياسات RLS.

---

### 6 & 7. ملحقات PostGIS و btree_gist و spatial_ref_sys (منخفض / يحتاج تأكيد - فحص وتوثيق ℹ️)
- **btree_gist**: تقع في schema `public`؛ نقلها ممكن لكن postgis لا تدعم تغيير الـ schema.
- **postgis**: محاولة `ALTER EXTENSION postgis SET SCHEMA extensions` تُرجع خطأ PostgreSQL الرسمي:
  > `ERROR: 0A000: extension "postgis" does not support SET SCHEMA`
- **spatial_ref_sys**: محاولة `ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY` تُرجع خطأ الملكية الرسمي:
  > `ERROR: 42501: must be owner of table spatial_ref_sys`
- **النتيجة**: هذا سلوك معروف وطبيعي لملحقة PostGIS المثبتة على PostgreSQL السحابي ولا يمثل ثغرة أمنية تطبيقية.

---

### 8. جداول مفعل عليها RLS بدون Policies (يحتاج تأكيد - فحص وتأكيد ✅)
- تم فحص الجداول:
  - 14 جدولاً في schema `private`: مخصصة للعمليات الداخلية عبر `SECURITY DEFINER` فقط.
  - `public.booking_holds`: محمي بالكامل حيث تم التحقق من سحب صلاحيات `SELECT/INSERT/UPDATE/DELETE` من `anon` و `authenticated` بالكامل (`anon_select = false, auth_select = false`)، والوصول محصور بـ `service_role` والدوال الآمنة (`acquire_booking_hold` و `release_booking_hold`).

---

### 9. مراجعة دوال anon المتاحة (منخفض - فحص وتأكيد الأمان ✅)
- `get_lounge_booking_capabilities`: ترجع فقط إعدادات تشغيل الصالة (مثل السماح بالحجز المستقبلي ونسب التأكيد) بدون أي بيانات مالية أو كاشيرات.
- `get_lounge_online_availability`: ترجع فقط `boolean` (متاحة أونلاين أم لا) بناءً على نبضات الكاشير.
- `get_lounge_activities`: ترجع أسعار الغرف العامة ومسميات الألعاب والأنشطة فقط.
- **النتيجة**: لا يوجد تسريب لأي بيانات حساسة لمستخدم غير مسجل دخول.

---

### 10. مفاتيح أجنبية غير مفهرسة (Foreign Keys Unindexed) (منخفض - تم الإصلاح ✅)
- **المشكلة**: وجود مفتاح أجنبي غير مفهرس: `booking_waitlist(hold_id)` مشيراً إلى `booking_holds(id)`.
- **الإصلاح**: إضافة فهرس مخصص `idx_booking_waitlist_hold_id`.
- **Migration**: `20261005124000_add_missing_fk_indexes.sql`
- **Commit**: [`540b85a`](https://github.com/salahaldensherief/Playspot_dashboard/commit/540b85a)
- **نتيجة الاختبار**: التحقق من خلو schema `public` من أي Foreign Key بدون Index (0 unindexed foreign keys).

---

## سجل الـ Commits على فرع `dev`
- `84c996a` fix(db): consolidate update_user_points into single audited RPC
- `ae00a31` fix(db): enforce payment before session start except for open time
- `14451e9` fix(db): remove pos from complete_booking_payment allowed methods
- `d34aa97` fix(db): consolidate redundant permissive RLS policies
- `9eff9aa` fix(db): consume applied voucher on booking payment completion
- `d853646` fix(db): preserve negotiated custom cost in approve_booking_extension
- `540b85a` perf(db): add index on booking_waitlist hold_id foreign key
