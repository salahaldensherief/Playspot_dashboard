import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';

void main() {
  for (final scale in [1.0, 1.6]) {
    testWidgets('dropdown keeps Arabic theme font at scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            theme: ThemeData(fontFamily: 'Tajawal'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomDropdown<String>(
                  label: 'الغرفة',
                  value: 'room',
                  items: const ['room'],
                  itemLabel: (_) => 'غرفة الألعاب',
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dropdown.style?.fontFamily, 'Tajawal');
      expect(dropdown.style?.fontSize, 14);
      expect(find.text('غرفة الألعاب'), findsWidgets);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
