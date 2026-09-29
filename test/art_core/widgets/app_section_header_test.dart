import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_icon_badge.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_section_header.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('AppIconBadge renders icon and triggers onTap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      buildTestableWidget(
        AppIconBadge(
          icon: Icons.sports_esports_outlined,
          color: AppColors.neonGreen,
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.byIcon(Icons.sports_esports_outlined), findsOneWidget);
    await tester.tap(find.byType(AppIconBadge));
    expect(tapped, isTrue);
  });

  testWidgets('AppSectionHeader renders title, badgeCount, and subtitle correctly', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const AppSectionHeader(
          title: 'Running Sessions',
          subtitle: 'Active now',
          icon: Icons.sports_esports_outlined,
          iconColor: AppColors.neonGreen,
          badgeCount: 5,
        ),
      ),
    );

    expect(find.text('Running Sessions'), findsOneWidget);
    expect(find.text('Active now'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(Icons.sports_esports_outlined), findsOneWidget);
  });
}
