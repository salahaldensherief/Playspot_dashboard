import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/widgets/data_table_widget.dart';

void main() {
  testWidgets('uses readable cards for table rows on mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selected = false;
    var actionPressed = false;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1920, 1080),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: DataTableWidget(
              columns: const ['Customer', 'Amount', 'Actions'],
              rows: [
                DataRow(
                  onSelectChanged: (_) => selected = true,
                  cells: [
                    const DataCell(Text('Salah')),
                    const DataCell(Text('150 EGP')),
                    DataCell(
                      IconButton(
                        onPressed: () => actionPressed = true,
                        icon: const Icon(Icons.open_in_new),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Salah'), findsOneWidget);
    expect(find.text('150 EGP'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.open_in_new));
    expect(actionPressed, isTrue);

    await tester.tap(find.text('Salah'));
    expect(selected, isTrue);
  });

  testWidgets(
    'fills the available desktop width without selection checkboxes',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(1920, 1080),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: DataTableWidget(
                  columns: const ['Customer', 'Room', 'Amount'],
                  rows: [
                    DataRow(
                      onSelectChanged: (_) {},
                      cells: const [
                        DataCell(Text('Salah')),
                        DataCell(Text('PS5 Room')),
                        DataCell(Text('150 EGP')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DataTable), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(tester.getSize(find.byType(DataTable)).width, greaterThan(1300));
      expect(tester.takeException(), isNull);
    },
  );
}
