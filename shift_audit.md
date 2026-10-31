# Shift Audit Report (`shift_audit.md`)
**PlaySpot Dashboard Project** | Audit Date: October 2026

---

> [!IMPORTANT]
> ### 🚨 أبرز النماذج: الكود المباشر على جدول `shifts`
> **نتيجة الفحص الدقيق للمشروع:**
> **لا توجد أي كتابة مباشرة (`insert`, `update`, `upsert`, `delete`) من واجهة المستخدم/التطبيق على جدول `shifts` أو `shift_expenses` أو `shift_payments`.**
> جميع عمليات إنشاء وإغلاق وتعديل واعتماد الشيفتات والمصروفات تتعدى طبقة قاعدة البيانات حصرياً عبر **Server-Authoritative RPCs** لضمان الأمن والتكامل.

---

## 1. الكتابة المباشرة على جداول الشيفتات (Direct Writes Audit)

| نوع العملية | الجدول Target Table | اسم الملف / المسار                                                                                                                                                                                          | رقم السطر | قطعة الكود (Code Snippet) | ملاحظات ونتائج الفحص |
| :--- | :--- |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| :--- | :--- | :--- |
| **Direct Write** | `shifts` | —                                                                                                                                                                                                           | — | *لا يوجد أي استدعاء `.from('shifts').insert/update/delete` في مشروع Flutter* | جميع التعديلات تتم عبر RPCs خادِمية (`open_lounge_shift`, `blind_close_shift`, `approve_shift`). |
| **Direct Read** | `shifts` | [َ`lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart#L31) | L31 | `_supabase.from('shifts').select('*, profiles:cashier_id(full_name)')` | استعلام قراءة فقط لجلب قائمة الشيفتات السابقة. |
| **Direct Read** | `shifts` | [`lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart#L90)  | L90 | `_supabase.from('shifts').select('*, profiles:cashier_id(...)').eq('status', 'open').isFilter('closed_at', null)` | استعلام قراءة فقط لجلب الشيفت المفتوح الحالي للمستخدم. |
| **Direct Read** | `shifts` | [`lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart#L215) | L215, L243 | `_supabase.from('shifts').select('id,lounge_id,cashier_id,...').eq('id', shiftId)` | قراءة للتحقق من هوية الكاشير ونطاق الصالة قبل استدعاء `blind_close_shift`. |
| **Direct Write** | `shift_expenses` | —                                                                                                                                                                                                           | — | *لا يوجد أي استدعاء `.from('shift_expenses').insert/update`* | إضافة المصروفات تتم حصرياً عبر RPC `add_shift_expense`. |
| **Direct Read** | `shift_expenses` | [`lib/features/shifts/data/data_sources/shift_details_remote_helper.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_details_remote_helper.dart#L37)      | L37 | `_supabase.from('shift_expenses').select('*, profiles:created_by(full_name)').eq('shift_id', shiftId)` | قراءة تفاصيل المصروفات والتوريدات لشيفت معين. |
| **Direct Write** | `shift_payments` | —                                                                                                                                                                                                           | — | *لا يوجد أي استدعاء `.from('shift_payments').insert/update`* | الدفعيات تُسجل تلقائياً عبر مشغلات وقواعد Backend مع الحجوزات والمبيعات. |
| **Direct Read** | `shift_payments` | [`lib/features/shifts/data/data_sources/shift_details_remote_helper.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_details_remote_helper.dart#L57)      | L57 | `_supabase.from('shift_payments').select('*').eq('shift_id', shiftId)` | قراءة دفعة المبيعات المسجلة للشيفت مع fallback على جدول الحجوزات عند الضرورة. |

---

## 2. استدعاءات الـ RPCs الخاصة بالشيفتات (Shift RPCs Audit)

| اسم الدالة (RPC Name) | اسم الملف / المسار | رقم السطر | قطعة الكود (Code Snippet) | الشاشة / السياق المستدعي (Caller Screen / Context) |
| :--- | :--- | :--- | :--- | :--- |
| **`open_lounge_shift`** | [`lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart#L188) | L188 | `await _supabase.rpc('open_lounge_shift', params: {'p_lounge_id': loungeId, 'p_starting_cash': startingCash, 'p_notes': notes})` | `OpenShiftDialog`, `AdminShiftMonitoringBar`, `ShiftHeaderBanner` (فتح شيفت جديد للكاشير الحالي بعهدة أولية). |
| **`open_lounge_shift`** | [`lib/features/lounges/data/datasources/lounge_remote_data_source_impl.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/lounges/data/datasources/lounge_remote_data_source_impl.dart#L225) | L225 | `await client.rpc('open_lounge_shift', params: {'p_lounge_id': loungeId, 'p_starting_cash': 0, 'p_notes': null})` | `LoungeProfileView` / `TopBarLoungeStatusToggle` (زر تغيير حالة الصالة إلى مفتوحة). |
| **`blind_close_shift`** | [`lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart#L226) | L226 | `await _supabase.rpc('blind_close_shift', params: {'p_shift_id': shiftId, 'p_cashier_id': cashierId, 'p_counted_cash': actualCash, 'p_notes': notes})` | `CloseShiftDialog`, `ShiftHeaderBanner`, `ShiftHandoverSummaryDialog` (إغلاق الشيفت المغلق/الأعمى بإدخال النقدية الفعلية فقط). |
| **`close_lounge_shift`** | [`lib/features/lounges/data/datasources/lounge_remote_data_source_impl.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/lounges/data/datasources/lounge_remote_data_source_impl.dart#L234) | L234 | `await client.rpc('close_lounge_shift', params: {'p_lounge_id': loungeId, 'p_actual_cash_counted': 0, 'p_notes': 'Closed via Lounge Toggle'})` | `LoungeProfileView` / `TopBarLoungeStatusToggle` (زر تغيير حالة الصالة إلى مغلقة - الإغلاق الاضطراري للصالة). |
| **`approve_shift`** | [`lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart#L266) | L266 | `await _supabase.rpc('approve_shift', params: {'p_shift_id': shiftId, 'p_manager_id': managerId, 'p_notes': notes})` | `ShiftHistoryScreen` (جدول سجل الورديات - زر اعتماد الشيفت المغلق من المدير/المالك). |
| **`add_shift_expense`** | [`lib/features/shifts/data/data_sources/shift_details_remote_helper.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_details_remote_helper.dart#L18) | L18 | `await _supabase.rpc('add_shift_expense', params: {'p_shift_id': expense.shiftId, 'p_amount': expense.amount, 'p_reason': expense.reason, 'p_type': expense.type})` | `AddExpenseDialog` (تسجيل المصروفات التشغيلية والتوريدات النقدية `expense` / `cash_drop`). |
| **`get_lounge_live_shift_overview`** | [`lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_remote_data_source_impl.dart#L166) | L166 | `await _supabase.rpc('get_lounge_live_shift_overview', params: {'p_lounge_id': loungeId})` | `AdminShiftMonitoringBar`, `ShiftHeaderBanner` (مراقبة حالة الشيفت المباشر، الإيراد، والمؤشرات اللحظية). |
| **`get_shift_report`** | [`lib/features/shifts/data/data_sources/shift_reporting_remote_helper.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_reporting_remote_helper.dart#L24) | L24 | `await _supabase.rpc('get_shift_report', params: {'p_lounge_id': ..., 'p_start_date': ..., 'p_end_date': ..., 'p_cashier_id': ...})` | `ShiftHistoryScreen` (فلترة واستخراج تقارير الورديات والشيفتات حسب الفترة والكاشير). |
| **`get_cashier_performance`** | [`lib/features/shifts/data/data_sources/shift_reporting_remote_helper.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_reporting_remote_helper.dart#L62) | L62 | `await _supabase.rpc('get_cashier_performance', params: {'p_lounge_id': ..., 'p_start_date': ..., 'p_end_date': ...})` | `CashierPerformanceWidget` (شاشة تقارير أداء ومقارنة الكاشيرية). |
| **`get_lounge_comparison`** | [`lib/features/shifts/data/data_sources/shift_reporting_remote_helper.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/data_sources/shift_reporting_remote_helper.dart#L97) | L97 | `await _supabase.rpc('get_lounge_comparison', params: {'p_start_date': ..., 'p_end_date': ...})` | `LoungeComparisonWidget` (مقارنة أداء الشيفتات بين الفروع المختلفة). |

---

## 3. أدوار المستخدمين في الكود (User Roles Audit)

| القيمة النصية للدور (Role Value String) | اسم الملف / المسار | رقم السطر | قطعة الكود (Code Snippet) | أين وكيف تتحدد / استخدامها |
| :--- | :--- | :--- | :--- | :--- |
| **`UserRole.superAdmin` / `'super_admin'`** | [`lib/art_core/layouts/dashboard_shell.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/art_core/layouts/dashboard_shell.dart#L92) | L92 | `final isSuperAdmin = user?.role == UserRole.superAdmin;` | تحديد منح صلاحية رؤية لوحة المراقبة الشاملة لجميع الصالات. |
| **`UserRole.owner` / `'owner'` / `'lounge_owner'`** | [`lib/art_core/layouts/dashboard_sidebar.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/art_core/layouts/dashboard_sidebar.dart#L110) | L110 | `if (user.role == UserRole.owner) return AppStrings.loungeOwnerLabel;` | عرض المسمى الوظيفي للمالك وشارات التحكم العليا بالفرع. |
| **`UserRole.manager` / `'manager'` / `'lounge_admin'`** | [`lib/art_core/layouts/dashboard_sidebar.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/art_core/layouts/dashboard_sidebar.dart#L111) | L111 | `if (user.role == UserRole.manager) return AppStrings.loungeManager;` | عرض مسمى مدير الفرع ومنحه صلاحيات الإشراف والاعتماد للشيفتات. |
| **`UserRole.cashier` / `'cashier'`** | [`lib/art_core/layouts/shell/dashboard_shell_content.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/art_core/layouts/shell/dashboard_shell_content.dart#L164) | L164 | `final isCashier = widget.user?.role == UserRole.cashier;` | تخصيص واجهة الكاشير (إغلاق إمكانية إلغاء الحوارات الإلزامية مثل فتح الشيفت). |
| **`UserRole.cashier` / `'cashier'`** | [`lib/art_core/layouts/shell/dashboard_shell_content.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/art_core/layouts/shell/dashboard_shell_content.dart#L322) | L322 | `final isDismissible = widget.user?.role != UserRole.cashier;` | منع الكاشير من إغلاق نافذة `OpenShiftDialog` دون تسجيل عهدة بداية الشيفت أو تسجيل الخروج. |
| **`UserPermissions` Checkers** | [`lib/features/auth/domain/entities/user_permissions.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/auth/domain/entities/user_permissions.dart#L15) | L15-L19 | `bool get isSuperAdmin => role == UserRole.superAdmin;`<br>`bool get isManager => role == UserRole.manager;`<br>`bool get isCashier => role == UserRole.cashier;` | دمج وتحديد الأدوار الرئيسية ومطابقتها مع جدول الصلاحيات الخادِمي. |
| **Catalog Normalization** | [`lib/features/permissions/data/data_sources/default_role_permissions_catalog.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/permissions/data/data_sources/default_role_permissions_catalog.dart#L6) | L6-L13 | `final isManager = cleanRole == 'manager' \|\| cleanRole == 'lounge_admin' \|\| cleanRole == 'owner' \|\| cleanRole == 'super_admin';` | تطبيع المسميات المختلفة للأدوار القيادية لمنح مفاتيح صلاحية الاعتماد الإداري بشكل موحد. |

---

## 4. فحص الصلاحيات ومفاتيح الأمان في الواجهة (Permission Keys Audit)

| مفتاح الصلاحية (Permission Key) | اسم الملف / المسار | رقم السطر | قطعة الكود (Code Snippet) | السلوك والمنطق المعروض/المخفي بناءً عليها |
| :--- | :--- | :--- | :--- | :--- |
| **`shifts_view`** | [`lib/art_core/layouts/sidebar/sidebar_navigation_items.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/art_core/layouts/sidebar/sidebar_navigation_items.dart#L105) | L105 | `final canViewShiftHistory = context.hasPermission('shifts_view');` | إظهار أو إخفاء تبويب/خيار "سجل الورديات" (Shift History) في القائمة الجانبية. |
| **`shifts_approve`**<br>*(Alias: `shifts_review_and_approve`)* | [`lib/features/shifts/presentation/shift_history/shift_history_screen.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/presentation/shift_history/shift_history_screen.dart#L171) | L171, L291 | `final canApprove = context.hasPermission('shifts_approve');` | إظهار أو إخفاء زر "اعتماد الشيفت" (`approveShift`) في جدول وسجل الشيفتات المغلقة للمدير/المالك فقط. |
| **`shift_view_expected_cash`**<br>*(Alias: `shifts_view_blind_cash`)* | [`lib/features/permissions/data/data_sources/default_role_permissions_catalog.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/permissions/data/data_sources/default_role_permissions_catalog.dart#L110) | L110 | `key: 'shift_view_expected_cash', isEnabled: isManager` | التحقق من حق الكشف عن المبلغ المتوقع تلقائياً (`expected_cash`). مُمكّن للمدير ومحجوب عن الكاشير لضمان الإغلاق الأعمى. |
| **`shift_close`**<br>*(Alias: `shifts_blind_close`)* | [`lib/features/permissions/domain/entities/permission_key.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/permissions/domain/entities/permission_key.dart#L17) | L17 | `'shift_close': 'shifts_blind_close'` | السماح للكاشير بإجراء الإغلاق الأعمى وتوجيهه لـ `blind_close_shift`. |
| **`shift_start`**<br>*(Alias: `shifts_open_own`)* | [`lib/features/permissions/domain/entities/permission_key.dart`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/permissions/domain/entities/permission_key.dart#L16) | L16 | `'shift_start': 'shifts_open_own'` | السماح للكاشير بفتح شيفت جديد بعهدته الخاصة. |

---

## 5. شاشة الكاشير ومبدأ الإغلاق الأعمى (Cashier Screen & Expected Cash Analysis)

> [!TIP]
> **تحليل شاشة إغلاق الشيفت (`CloseShiftDialog`):**
> - **هل يُعرض الكاش المتوقع (`expected_cash`) للكاشير قبل الإغلاق؟** **لا، مطلقاً (No).**
> - في حوار الإغلاق [`CloseShiftDialog`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/presentation/shift_management/widgets/close_shift_dialog.dart#L15)، يتم طلب المبلغ الفعلي المحسوب يدوياً من الكاشير فقط (`_cashController` / `actualCash`) دون إظهار أي أرقام محسوبة من النظام.
> - متغيّر `expectedCash` الممرر للحوار يُتجاهل تماماً (`// Ignored for blind closing compliance`).
> - **بعد تقديم الإغلاق واستلام النتيجة من الـ RPC (`blind_close_shift`):** يتم عرض ملخص التسليم وإيصال Z-Report في [`ShiftHandoverSummaryDialog`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/presentation/shift_management/widgets/shift_handover_summary_dialog.dart#L20) و[`ShiftSummaryModal`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/presentation/shift_management/widgets/shift_summary_modal.dart#L12) لإظهار العجز/الزيادة النهائية فقط بعد اعتماد التسجيل السري.

---

## 6. فحص الـ Edge Functions والـ Webhooks

| أداة / Edge Function | اسم الملف / المسار | يكتب على `shifts`؟ | التفاصيل والملاحظات |
| :--- | :--- | :--- | :--- |
| `create-lounge-owner` | `supabase/functions/create-lounge-owner/index.ts` | **لا (No)** | يختص بإنشاء وتأكيد تجهيز حساب مالك الصالة الجديد. |
| `create-lounge-staff` | `supabase/functions/create-lounge-staff/index.ts` | **لا (No)** | يختص بإنشاء موظفي الصالة وتسجيل أدوارهم في `lounge_staff`. |
| `deactivate-lounge-admin` | `supabase/functions/deactivate-lounge-admin/index.ts` | **لا (No)** | يختص بتعطيل حسابات المدراء. |
| `delete-account` | `supabase/functions/delete-account/index.ts` | **لا (No)** | يختص بحذف وتعطيل الحسابات. |
| `update-user-location` | `supabase/functions/update-user-location/index.ts` | **لا (No)** | يختص بتحديث الموقع الجغرافي للصالة/المستخدم في `profiles` و`lounges`. |

---

## 7. تعاريف الشيفت في الكود (Shift Model & Entity Schema Definitions)

تعتمد الطبقات البرمجية النموذج التالي لجدول البيانات لتأكيد توافق الـ RPCs مع التطبيق ([`ShiftModel`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/data/models/shift_model.dart) & [`ShiftEntity`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/domain/entities/shift_entity.dart)):

| حقل النموذج (Dart Field) | مفاتيح الـ JSON المتوقعة (JSON Map Keys) | النوع (Data Type) | الوصف والدور |
| :--- | :--- | :--- | :--- |
| `id` | `id`, `shift_id` | `String` | معرف الشيفت الفريد (UUID). |
| `loungeId` | `lounge_id`, `loungeId` | `String?` | معرف الصالة/الفرع. |
| `cashierId` | `cashier_id`, `staff_id`, `staff_user_id` | `String` | معرف الكاشير صاحب الشيفت. |
| `cashierName` | `profiles.full_name`, `cashier_name` | `String?` | اسم الكاشير الكامل. |
| `startingCash` | `starting_cash`, `opening_cash` | `double` | عهدة بداية الشيفت النقدي. |
| `cashRevenue` | `total_cash_sales`, `cash_revenue` | `double?` | إجمالي المبيعات والحجوزات النقدية. |
| `digitalRevenue` | `total_digital_sales`, `digital_revenue` | `double?` | إجمالي المبيعات الرقمية (شبكة/محفظة). |
| `expensesTotal` | `total_expenses`, `expenses_total` | `double?` | إجمالي المصروفات التشغيلية المخصومة. |
| `cashDropsTotal` | `total_cash_drops`, `cash_drops_total` | `double?` | إجمالي النقدية الموردة للخزينة أثناء الشيفت. |
| `expectedCash` | `expected_cash` | `double?` | النقدية المتوقعة (`startingCash + cashRevenue - expensesTotal - cashDropsTotal`). |
| `actualCash` | `actual_cash_counted`, `actual_cash` | `double?` | النقدية الفعلية التي أدخلها الكاشير عند الإغلاق. |
| `discrepancy` | `difference`, `discrepancy` | `double?` | الفارق النقدية (`actualCash - expectedCash`). |
| `status` | `status` | `String` | حالة الشيفت (`'open'` أو `'closed'`). |
| `startTime` | `created_at`, `start_time`, `opened_at` | `DateTime` | تاريخ ووقت فتح الشيفت. |
| `endTime` | `end_time`, `closed_at` | `DateTime?` | تاريخ ووقت إغلاق الشيفت. |
| `notes` | `notes` | `String?` | ملاحظات الكاشير عند الإغلاق. |
| `isApproved` | `is_approved` | `bool` | هل تم اعتماد الشيفت إدارياً؟ |
| `approvedBy` | `approved_by` | `String?` | معرف المدير الذي اعتمد الشيفت. |
| `approvedAt` | `approved_at` | `DateTime?` | تاريخ ووقت الاعتماد الإداري. |
| `managerNotes` | `manager_notes` | `String?` | ملاحظات المدير عند الاعتماد. |

---

## 8. قرارات البيزنيس والتوصيات البرمجية (Business Decisions & Recommendations)

### 1️⃣ هل الكاشير يقدر يعتمد شيفته لوحده؟
- **الوضع الحالي في الكود:** **لا (No).** كود التطبيق في [`ShiftHistoryScreen`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/presentation/shift_history/shift_history_screen.dart#L171) يتطلب صلاحية `shifts_approve` (المنوحة حصرياً للمدير والمالك `isManager`) لاستدعاء الـ RPC الخادِمي `approve_shift(p_shift_id, p_manager_id, p_notes)`.
- **التوصية:** هذا التصميم ممتاز ويتبع مبدأ **توزيع المسؤوليات والرقابة المزدوجة (Dual-Control)**، حيث يقوم الكاشير بالإغلاق الأعمى فقط، ثم يراجع المدير المبالغ والتقارير المترتبة ويقوم بالاعتماد.

### 2️⃣ الكاش المتوقع: يطرح كل المصروفات، ولا بس أنواع معينة؟
- **الوضع الحالي في الكود:**
  - معادلة النقدية المتوقعة في [`ShiftEntity.calculatedExpectedCash`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/domain/entities/shift_entity.dart#L33):
    $$\text{Expected Cash} = \text{Starting Cash} + \text{Cash Revenue} - \text{Expenses Total} - \text{Cash Drops Total}$$
  - الأنواع المستخدمة فعلياً في شاشة إضافة المصروفات [`AddExpenseDialog`](file:///D:/flutter_projects/play_spot_dashboard/lib/features/shifts/presentation/shift_management/widgets/add_expense_dialog.dart#L100) هي:
    1. `'expense'` (مصروف تشغيلي)
    2. `'cash_drop'` (توريد نقدية إلى الخزينة الرئيسية)
- **التوصية:** كلا النوعين يمثل خروج نقدية فيزيكال من درج الكاشير، وبالتالي يقللان من النقدية المتبقية في الدرج، وطرحهما معاً هو المنطق الحسابي الصحيح والآمن.

### 3️⃣ هل السوبر أدمن المفروض يتدخل في تشغيل الشيفتات، أم يكتفي بالمراجعة والاعتماد؟
- **الوضع الحالي في الكود:** السوبر أدمن لديه صلاحية الرؤية والمراقبة الشاملة لجميع الفروع والصالات (`isSuperAdmin`) عبر `AdminShiftMonitoringBar` وشاشة التقارير، بينما فتح الشيفت الميداني وإغلاقه يتطلب الارتباط بصالة محددة وكاشير فعلي مباشر.
- **التوصية:** يُفضل أن يقتصر دور السوبر أدمن على **المراقبة والاستعراض والاعتماد الإداري/المراجعة**، مع إبقاء الفتح والإغلاق الميداني مرتبكاً بالكاشير والمدير المباشر للصالة لضمان دقة مسار التدقيق القانوني (Audit Trail).
