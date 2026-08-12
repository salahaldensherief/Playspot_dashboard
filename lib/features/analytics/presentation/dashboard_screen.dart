import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_stats_grid.dart';
import 'widgets/dashboard_charts_row.dart';
import 'widgets/dashboard_bottom_section.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';

class DashboardScreen extends StatelessWidget {
  final UserRole role;
  
  const DashboardScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = role == UserRole.superAdmin;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(isSuperAdmin: isSuperAdmin),
          SizedBox(height: 32.h),
          DashboardStatsGrid(isSuperAdmin: isSuperAdmin),
          SizedBox(height: 32.h),
          const DashboardChartsRow(),
          SizedBox(height: 32.h),
          DashboardBottomSection(isSuperAdmin: isSuperAdmin),
        ],
      ),
    );
  }
}
