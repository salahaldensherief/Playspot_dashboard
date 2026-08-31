import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_stats_grid.dart';
import 'widgets/lounge_owner_analytics_grid.dart';
import 'widgets/dashboard_charts_row.dart';
import 'widgets/dashboard_bottom_section.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_activities.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1200;

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(isSuperAdmin: isSuperAdmin),
              SizedBox(height: 20.h),
              if (isSuperAdmin)
                DashboardStatsGrid(isSuperAdmin: isSuperAdmin)
              else
                const LoungeOwnerAnalyticsGrid(),
              SizedBox(height: 20.h),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          const DashboardChartsRow(),
                          SizedBox(height: 20.h),
                          DashboardBottomSection(isSuperAdmin: isSuperAdmin),
                        ],
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          const QuickActionsCard(),
                          SizedBox(height: 20.h),
                          const RecentActivityCard(),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    const DashboardChartsRow(),
                    SizedBox(height: 20.h),
                    const QuickActionsCard(),
                    SizedBox(height: 20.h),
                    DashboardBottomSection(isSuperAdmin: isSuperAdmin),
                    SizedBox(height: 20.h),
                    const RecentActivityCard(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
