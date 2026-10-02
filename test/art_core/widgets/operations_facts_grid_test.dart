import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/widgets/operations_facts_grid.dart';
import 'package:play_spot_dashboard/art_core/theme/operations_tokens.dart';

void main() {
  for (final width in [360.0, 600.0, 1024.0]) {
    for (final scale in [1.0, 1.6, 3.0]) {
      testWidgets(
        'facts preserve Arabic values and directional order at $width scale=$scale',
        (tester) async {
          tester.view.physicalSize = const Size(1440, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child ?? const SizedBox.shrink(),
              ),
              home: Scaffold(
                body: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: SizedBox(
                      width: width,
                      child: const OperationsFactsGrid(
                        children: [
                          Text(
                            'بيانات العميل — محمد أحمد',
                            key: ValueKey('first'),
                            style: OperationsTokens.value,
                          ),
                          Text(
                            'المبلغ المتبقي للدفع',
                            key: ValueKey('second'),
                            style: OperationsTokens.value,
                          ),
                          Text(
                            'تفاصيل الحجز التالي',
                            key: ValueKey('third'),
                            style: OperationsTokens.value,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          final first = tester.getRect(find.byKey(const ValueKey('first')));
          final second = tester.getRect(find.byKey(const ValueKey('second')));
          for (final key in ['first', 'second', 'third']) {
            final rect = tester.getRect(find.byKey(ValueKey(key)));
            expect(rect.width, greaterThan(0));
            expect(rect.width, lessThanOrEqualTo(width));
            expect(rect.left, greaterThanOrEqualTo(1440 - width));
            expect(rect.right, lessThanOrEqualTo(1440));
          }
          if (first.top == second.top) {
            expect(first.left, greaterThan(second.left));
          } else {
            expect(second.top, greaterThanOrEqualTo(first.bottom));
          }
        },
      );
    }
  }
}
