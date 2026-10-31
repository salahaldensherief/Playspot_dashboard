import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/live_indicator_badge.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';

class DashboardHeader extends StatelessWidget {
  final bool isSuperAdmin;
  final Future<void> Function()? onRefresh;
  final Widget? trailing;

  const DashboardHeader({
    super.key,
    required this.isSuperAdmin,
    this.onRefresh,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12.w,
                runSpacing: 8.h,
                children: [
                  Text(
                    isSuperAdmin
                        ? AppStrings.globalOverview
                        : AppStrings.loungePerformance,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  if (!isSuperAdmin) const LiveIndicatorBadge(),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                isSuperAdmin
                    ? AppStrings.globalPerformanceDesc
                    : AppStrings.loungeOperationsDesc,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        BlocSelector<DashboardCubit, DashboardState, FeatureStatus>(
          selector: (state) => state.status,
          builder: (context, status) {
            final bool isLoading = status == FeatureStatus.loading;

            return IconButton(
              tooltip: AppStrings.refreshData,
              onPressed: isLoading
                  ? null
                  : () {
                      final refresh = onRefresh;
                      if (refresh != null) {
                        refresh();
                      } else {
                        context.read<DashboardCubit>().loadDashboardData();
                      }
                    },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.cardBackground,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: const BorderSide(color: AppColors.borderDefault),
                ),
              ),
              icon: isLoading
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
            );
          },
        ),
      ],
    );

    final trailingAction = trailing;
    if (trailingAction == null) return header;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        if (constraints.maxWidth < 720 * textScale.clamp(1, 1.6)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              SizedBox(height: 16.h),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: trailingAction,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: header),
            SizedBox(width: 12.w),
            trailingAction,
          ],
        );
      },
    );
  }
}
