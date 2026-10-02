import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/widgets/dashboard_flow_layout.dart';

void main() {
  testWidgets(
    'the next main card starts 16px below its feed despite a tall sidebar',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardFlowLayout(
              main: const [
                SizedBox(key: Key('feed'), height: 100),
                SizedBox(key: Key('next'), height: 100),
              ],
              aside: const [SizedBox(key: Key('sidebar'), height: 600)],
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('next'))).dy -
            tester.getBottomLeft(find.byKey(const Key('feed'))).dy,
        16,
      );
      expect(tester.getTopLeft(find.byKey(const Key('sidebar'))).dy, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'narrow content after navigation and enlarged text stack columns',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final (width, scale) in [(704.0, 1.0), (1000.0, 1.6)]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: SizedBox(
                  width: width,
                  child: DashboardFlowLayout(
                    main: const [SizedBox(key: Key('main'), height: 100)],
                    aside: const [SizedBox(key: Key('aside'), height: 500)],
                  ),
                ),
              ),
            ),
          ),
        );
        expect(
          tester.getTopLeft(find.byKey(const Key('aside'))).dy -
              tester.getBottomLeft(find.byKey(const Key('main'))).dy,
          16,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
