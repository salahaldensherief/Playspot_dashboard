# خطة تحسين وتطوير UI/UX ويدجت الحجوزات النشطة (Active Bookings Widget)

تحسين واجهة وتجربة المستخدم (UI/UX) لويدجت كروت الحجوزات النشطة والجلسات الحية (`LiveSessionCard` / `BookingsActiveGrid` / `CashierSessionsWorkspace`) في لوحة تحكم PlaySpot لتكون أكثر سلاسة، وضوحاً، واحترافية وفقاً لهوية التطبيق الداكنة (Dark Neon Dashboard).

---

## User Review Required

> [!IMPORTANT]
> **التغييرات الرئيسية والتحسينات المقترحة:**
> 1. **تصحيح نصوص الجلسات المفتوحة (Open-Time Sessions):**
>    - تعديل عنوان العداد في الجلسات المفتوحة من "الوقت المتبقي" إلى "الوقت المنقضي" (`cashier.elapsed`).
>    - إخفاء أزرار التمديد السريع (+15د، +30د، +1س) في الجلسات المفتوحة لأنها غير قابلة للتمديد بدقائق محددة، وإبقاؤها فقط للجلسات المحددة المدة.
> 2. **مؤشر البث الحي (Pulsing Live Indicator):**
>    - إضافة نقطة ضوئية متوهجة نابضة (Glowing Pulsing Dot) بجانب حالة "قيد التشغيل" لإعطاء انطباع بصري لحظي ومباشر.
> 3. **تطوير واجهة شاشة العمليات السريعة (`CashierSessionTile` & `CashierSessionsWorkspace`):**
>    - إعادة تصميم كروت الجلسات في القائمة الجانبية بشاشات الكاشير لتبدو بطابع الزجاج الداكن (Glassmorphic Dark Theme) مع إظهار اسم الغرفة، العميل، المؤقت اللحظي، وحالة الدفع بشكل متناسق بدلاً من النصوص العادية غير المنسقة.
>    - معالجة الحالة الفارغة (Empty State) بتصميم أنيق وموضح عند عدم وجود جلسات نشطة.
> 4. **تحسين شبكة الكروت وتقسيم العرض (`BookingsActiveGrid`):**
>    - تحسين أبعاد الكروت وتفادي التمرير المزدوج داخل الكرت عبر تحسين مرونة الهيكل والتجاوب على الشاشات المختلفة.
>    - تحسين وضوح أزرار العمليات السريعة (إنهاء الجلسة، إضافة كانتين/خدمات، تمديد الوقت، وتحسيب الأوبن تايم).

---

## Proposed Changes

### 1. [lib/art_core/app_strings.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/art_core/app_strings.dart)
- إضافة Getter لنص `elapsedTime` للوصول السريع إلى ترجمة "الوقت المنقضي".

### 2. [lib/features/bookings/presentation/widgets/live_session_timer_box.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/widgets/live_session_timer_box.dart)
- [MODIFY] تحديث نص العنوان بناءً على نوع الحجز:
  - إذا كانت الجلسة منتهية -> `timeExpired` ("تجاوز الوقت / منتهية")
  - إذا كانت الجلسة مفتوحة (`booking.isOpenEnded`) -> `AppStrings.elapsedTime` ("الوقت المنقضي")
  - إذا كانت جلسة بمؤقت -> `AppStrings.remainingTime` ("الوقت المتبقي")
- [MODIFY] إخفاء أزرار التمديد السريع (+15د، +30د، +1س) عند `booking.isOpenEnded == true`.
- [MODIFY] تحسين التصميم البصري لبطاقة المؤقت وأزرار التمديد بشرائح تفاعلية متناسقة.

### 3. [lib/features/bookings/presentation/widgets/live_session_card_header.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/widgets/live_session_card_header.dart)
- [MODIFY] إضافة مؤشر متوهج نبضي (Pulsing Green Dot) لجلسات "قيد التشغيل".
- [MODIFY] إظهار شارة تميز بين الجلسة المفتوحة (Open Time) والجلسة ذات المدة المحددة.
- [MODIFY] تحسين شكل أزرار تغيير الغرفة والتحكم بالسيرفر/الجهاز.

### 4. [lib/features/bookings/presentation/widgets/cashier_session_tile.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/widgets/cashier_session_tile.dart)
- [MODIFY] إعادة بناء الكرت بتصميم زجاجي داكن مع زوايا دائرية، حواف متوهجة حسب حالة الجلسة (نشطة/تجاوزت الوقت/مفتوحة)، شارة حالة الدفع، وعرض العداد الحقيقي المباشر.

### 5. [lib/features/bookings/presentation/widgets/cashier_sessions_workspace.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/widgets/cashier_sessions_workspace.dart)
- [MODIFY] استبدال النص العادي للحالة الفارغة بـ `AppEmptyStateWidget` منسق وأنيق عند عدم وجود جلسات نشطة.

### 6. [lib/features/bookings/presentation/widgets/live_session_card.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/widgets/live_session_card.dart)
- [MODIFY] تحسين التجاوب البصري والتمرير الداخلي للكرت لمنع حدوث مشاكل في الأبعاد داخل GridView.
- [MODIFY] تحسين التفاعل عند الحوم (Hover effects) وضبط الظلال والحواف التفاعلية.

### 7. [lib/features/bookings/presentation/widgets/bookings_active_grid.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/widgets/bookings_active_grid.dart)
- [MODIFY] تحسين شبكة الكروت والتأكد من إمكانية التنقل السلس والواضح بين عرض الشبكة وعرض الجدول ولوحة العمليات.

---

## Verification Plan

### Automated Tests
- تشغيل فحص الأكواد والتحليل المكتبي:
  `flutter analyze --no-fatal-infos`
- تشغيل اختبارات موديول الحجوزات:
  `flutter test test/features/bookings/`

### Manual Verification
- فتح شاشة الحجوزات النشطة ومراجعة الجلسات المفتوحة والجلسات المحددة بوقت.
- التأكد من إظهار "الوقت المنقضي" للجلسات المفتوحة و"الوقت المتبقي" للجلسات المحددة.
- التأكد من اختفاء أزرار التمديد السريع في الجلسات المفتوحة وظهورها في الجلسات المحددة.
- مراجعة استجابة التصميم والتأكد من ملاءمته للشاشات المختلفة وأسلوب اللوحة الداكن.
