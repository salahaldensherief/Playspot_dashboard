import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_stats_grid.dart';
import 'widgets/lounge_owner_analytics_grid.dart';
import 'widgets/dashboard_charts_row.dart';
import 'widgets/dashboard_bottom_section.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'cubit/lounge_stats_cubit.dart';

class DashboardScreen extends StatefulWidget {
  final UserRole role;
  
  const DashboardScreen({
    super.key,
    required this.role,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.role != UserRole.superAdmin) {
      final loungeId = context.read<LoginCubit>().state.user?.loungeId;
      context.read<LoungeStatsCubit>().fetchStats(loungeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = widget.role == UserRole.superAdmin;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(isSuperAdmin: isSuperAdmin),
          SizedBox(height: 32.h),
          if (isSuperAdmin)
            DashboardStatsGrid(isSuperAdmin: isSuperAdmin)
          else
            const LoungeOwnerAnalyticsGrid(),
          SizedBox(height: 32.h),
          const DashboardChartsRow(),
          SizedBox(height: 32.h),
          DashboardBottomSection(isSuperAdmin: isSuperAdmin),
        ],
      ),
    );
  }
}
