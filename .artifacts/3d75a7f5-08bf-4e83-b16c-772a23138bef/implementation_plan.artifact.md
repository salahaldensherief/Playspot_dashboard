# خطة تنفيذ: تحويل الداشبورد لتصميم Responsive بالكامل، إضافة Quick Actions، والتنبيهات اللحظية

تحويل واجهة **PlaySpot Web Dashboard** لتجربة مستخدم متجاوبة وسلسة عبر جميع الأجهزة (Mobile < 600px, Tablet 600px–1024px, Desktop > 1024px)، مع دعم التبديل السريع لحالة الغرف (One-Tap Quick Toggle) وإشعارات الحجوزات الفورية (الصوتية والمرئية)، وتجهيز ملفات الـ PWA للتثبيت على الموبايل.

---

## 1. معمارية التصميم والتجاوب (Responsive Layout)
- **Breakpoints**: الاعتماد على `AppBreakpoints` لتحديد 3 أحجام شاشات:
  - **Mobile (< 600px)**: شريط التنقل يتحول إلى Drawer منزلق بدلاً من القائمة الجانبية.
  - **Tablet (600px – 1024px)**: القائمة الجانبية تُعرض جانبيًا مع الحفاظ على مساحة العرض الرئيسية.
  - **Desktop (> 1024px)**: عرض الداشبورد الكامل مع Sidebar ثابت وسيع.
- **عرض البيانات والجداول**:
  - تحويل الـ DataTables على الموبايل تلقائياً إلى Cards رأسية مع أبعاد touch targets لا تقل عن 48x48 dp.

---

## 2. التفاعل السريع للغرف (One-Tap Room Toggle)
- إضافة زر تغيير حالة سريع (Quick Toggle Button) على كل كارت غرفة في `RoomOccupancyGrid` وشاشة إدارة الغرف `RoomsDataTable`.
- التبديل بلمسة واحدة بين `متاحة (Available)` و `مشغولة - حجز مباشر (Occupied - Walk-in)`.
- تنفيذ التحديث عبر `RoomCubit` باستخدام **Optimistic UI** مؤشرات تحميل مصغرة (`updatingRoomIds`) لمنع الضغط المزدوج.

---

## 3. التنبيهات اللحظية المرئية والصوتية (Realtime Alerts)
- عند وصول حجز جديد عبر Supabase Realtime:
  1. تشغيل صوت التنبيه فوراً عبر `AudioService.playNotificationSound()`.
  2. إظهار **Banner / Dialog** بارز يضم تفاصيل الحجز (اسم العميل، الأوضة، الوقت، السعر) مع أزرار [تأكيد الحجز] و [إغلاق].

---

## 4. إعدادات الـ PWA واللغات (PWA & Localization)
- تحديث `web/manifest.json` ليدعم نمط Standalone بالكامل، بألوان هكسا `#0b0e14` وتكوين الأيقونات.
- إضافة مصطلحات عامية مصرية للصالات في ملفات الترجمة (مثل "أوضة" و"حجز مباشر").

---

## Proposed Changes

### Core & Layout
#### [MODIFY] [app_breakpoints.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/core/responsive/app_breakpoints.dart)
- ضمان دقة نقاط التجاوب وتوفير دالات فحص مريحة.

#### [MODIFY] [dashboard_shell.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/art_core/layouts/dashboard_shell.dart)
- تحديث التجاوب: عرض Sidebar جانبي للديسكتوب والتابلت (width >= 600px) وتحويله إلى Drawer للموبايل (< 600px).
- إضافة `BlocListener<BookingCubit, BookingState>` لعرض حوار التنبيه الفوري عند وصول حجز جديد.

#### [MODIFY] [dashboard_top_bar.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/art_core/layouts/dashboard_top_bar.dart)
- ضبط المظهر للشاشات الصغيرة لتجنب Overflow وإبراز زر القائمة للموبايل.

---

### Rooms Feature (Quick Actions & Walk-in Toggle)
#### [MODIFY] [room_repository_impl.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/rooms/data/repositories/room_repository_impl.dart)
- دعم تحويل حالة الغرفة إلى `occupied` و `available` في Supabase DB.

#### [MODIFY] [room_state.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/rooms/presentation/cubit/room_state.dart)
- إضافة `updatingRoomIds` لتتبع الغرف التي جاري تحديث حالتها لمنع الضغط المزدوج وإظهار Loading مصغر.

#### [MODIFY] [room_cubit.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/rooms/presentation/cubit/room_cubit.dart)
- إضافة دالة `toggleWalkInStatus(String roomId, RoomStatusEnum currentStatus)` مع Optimistic UI وRollback في حال الفشل.

#### [MODIFY] [room_occupancy_grid.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/widgets/room_occupancy_grid.dart)
- إضافة زر Quick Toggle سريع في كل كارت غرفة لتسجيل حجز مباشر (Walk-in) فورياً.

#### [MODIFY] [rooms_data_table.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/rooms/presentation/widgets/rooms_data_table.dart)
- تحويل جدول الغرف إلى Cards مريحة على الموبايل وإضافة زر التبديل السريع.

---

### Realtime Bookings Alert
#### [MODIFY] [booking_state.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/cubit/booking_state.dart)
- إضافة `latestNewBooking` للحالة للاستماع لها في الـ UI عند وصول حجز جديد.

#### [MODIFY] [booking_cubit.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/cubit/booking_cubit.dart)
- تشغيل صوت التنبيه وتعيين `latestNewBooking` عند وصول حجز جديد عبر سوبابيز Realtime.

#### [NEW] [new_booking_alert_dialog.dart](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/lib/features/bookings/presentation/widgets/new_booking_alert_dialog.dart)
- حوار تنبيه مرئي أنيق ومميز يظهر للكاشير فور وصول حجز جديد مع أزرار التأكيد والإغلاق.

---

### PWA Configuration
#### [MODIFY] [manifest.json](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/web/manifest.json)
- تحديث إعدادات الـ PWA، الاسم العربي والوصفي، نمط Display الخارجي والوان الثيم.

#### [MODIFY] [ar.json](file:///Users/ix-solution2/Desktop/work/projects/Playspot_dashboard/assets/translations/ar.json)
- إضافة مفاتيح الترجمة الخاصة بالحجز المباشر وتنبيهات الحجوزات والأنشطة السريعة.

---

## Verification Plan

### Automated Verification
- إجراء فحص برمجي بدون أخطاء `flutter analyze` للتأكد من خلو المشروع من أية أخطاء.

### Manual Verification
- تجربة التجاوب على أبعاد الموبايل (< 600px)، التابلت (768px)، والديسكتوب (1280px).
- اختبار زر تغيير حالة الغرفة السريع بلمسة واحدة (Walk-in Toggle) والتأكد من التحديث اللحظي.
- اختبار محاكاة حجز جديد والتأكد من تشغيل صوت التنبيه وصعود dialog التنبيه الفوري.
- التأكد من إمكانية تثبيت الداشبورد كـ PWA عبر المتصفح.
