import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';

class DashboardHeader extends StatelessWidget {
  final bool isSuperAdmin;
  final Future<void> Function()? onRefresh;

  const DashboardHeader({
    super.key,
    required this.isSuperAdmin,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSuperAdmin ? AppStrings.globalOverview : AppStrings.loungePerformance,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                isSuperAdmin 
                  ? AppStrings.globalPerformanceDesc
                  : AppStrings.loungeOperationsDesc,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        BlocSelector<DashboardCubit, DashboardState, FeatureStatus>(
          selector: (state) => state.status,
          builder: (context, status) {
            final bool isLoading = status == FeatureStatus.loading;

            return MouseRegion(
              cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
              child: InkWell(
                onTap: isLoading
                    ? null
                    : () {
                        if (onRefresh != null) {
                          onRefresh!();
                        } else {
                          context.read<DashboardCubit>().loadDashboardData();
                        }
                      },
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.neonBlue,
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: AppColors.neonBlue,
                          size: 22.r,
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
