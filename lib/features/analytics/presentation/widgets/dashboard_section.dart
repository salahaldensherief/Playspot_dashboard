import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/core/responsive/app_breakpoints.dart';

enum DashboardSpan { full, half, twoThirds, oneThird }

class DashboardSection {
  final Widget widget;
  final int priority;
  final DashboardSpan span;

  const DashboardSection({
    required this.widget,
    required this.priority,
    required this.span,
  });
}

class DashboardSectionLayout extends StatelessWidget {
  final List<DashboardSection> sections;

  const DashboardSectionLayout({
    super.key,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final sortedSections = List<DashboardSection>.from(sections)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final isDesktop = AppBreakpoints.isDesktop(context);
    final isTablet = AppBreakpoints.isTablet(context);

    if (!isDesktop && !isTablet) {
      final mobileItems = sortedSections
          .map((s) => Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: s.widget,
              ))
          .toList();

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => mobileItems[index],
          childCount: mobileItems.length,
        ),
      );
    }

    // Responsive Layout Distribution Engine (Desktop & Tablet)
    final List<Widget> rows = [];
    int index = 0;

    while (index < sortedSections.length) {
      final current = sortedSections[index];

      if (current.span == DashboardSpan.full) {
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: current.widget,
          ),
        );
        index++;
      } else if (current.span == DashboardSpan.twoThirds || current.span == DashboardSpan.half) {
        // Collect consecutive split-screen pairs into unified left & right columns
        final List<Widget> leftWidgets = [];
        final List<Widget> rightWidgets = [];

        while (index < sortedSections.length &&
            (sortedSections[index].span == DashboardSpan.twoThirds ||
                sortedSections[index].span == DashboardSpan.half)) {
          final leftSection = sortedSections[index];
          leftWidgets.add(leftSection.widget);
          index++;

          if (index < sortedSections.length &&
              (sortedSections[index].span == DashboardSpan.oneThird ||
                  sortedSections[index].span == DashboardSpan.half)) {
            final rightSection = sortedSections[index];
            rightWidgets.add(rightSection.widget);
            index++;
          }
        }

        if (leftWidgets.isNotEmpty) {
          if (rightWidgets.isEmpty) {
            for (var w in leftWidgets) {
              rows.add(Padding(padding: EdgeInsets.only(bottom: 16.h), child: w));
            }
          } else {
            rows.add(
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isDesktop ? 7 : 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < leftWidgets.length; i++) ...[
                            if (i > 0) SizedBox(height: 16.h),
                            leftWidgets[i],
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      flex: isDesktop ? 3 : 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < rightWidgets.length; i++) ...[
                            if (i > 0) SizedBox(height: 16.h),
                            rightWidgets[i],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      } else {
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: current.widget,
          ),
        );
        index++;
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => rows[index],
        childCount: rows.length,
      ),
    );
  }
}
