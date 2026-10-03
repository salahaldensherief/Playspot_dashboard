import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/widgets/stat_card.dart';

void main() {
  testWidgets('occupied/total remains left to right inside an Arabic card', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1440, 900),
        builder: (context, child) => const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: StatCard(
                title: 'الغرف المشغولة',
                value: '0 / 7',
                subtitle: 'حالة الصالة',
                valueTextDirection: TextDirection.ltr,
                icon: Icons.meeting_room,
                iconColor: Colors.cyan,
              ),
            ),
          ),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(find.text('0 / 7'));
    final occupied = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .single;
    final total = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 4, extentOffset: 5),
        )
        .single;
    expect(occupied.left, lessThan(total.left));
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('الغرف المشغولة'))
          .textDirection,
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
