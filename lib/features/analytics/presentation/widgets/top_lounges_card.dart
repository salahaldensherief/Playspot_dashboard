import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/shimmer_loading.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';
import 'lounge_performance_item.dart';

class TopLoungesCard extends StatelessWidget {
  const TopLoungesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.topLounges != curr.topLounges,
        builder: (context, state) {
          if (state.status == FeatureStatus.loading &&
              state.topLounges.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading.rounded(width: 180.w, height: 20.h),
                SizedBox(height: 8.h),
                ShimmerLoading.rounded(width: 120.w, height: 14.h),
                SizedBox(height: 20.h),
                ...List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: ShimmerLoading.rounded(
                      width: double.infinity,
                      height: 48.h,
                    ),
                  ),
                ),
              ],
            );
          }

          if (state.topLounges.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 36.r,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(height: 10.h),
                    AppText.body(
                      AppStrings.noResultsMatching.replaceFirst("\"{}\"", ""),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.heading(AppStrings.topPerformingLounges, fontSize: 18.sp),
              SizedBox(height: 4.h),
              AppText.body(
                AppStrings.topPerformingLoungesSubtitle,
                fontSize: 13.sp,
              ),
              SizedBox(height: 24.h),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.topLounges.length > 5
                    ? 5
                    : state.topLounges.length,
                separatorBuilder: (context, index) =>
                    Divider(color: AppColors.borderDefault, height: 24.h),
                itemBuilder: (context, index) {
                  final lounge = state.topLounges[index];
                  return LoungePerformanceItem(
                    name:
                        lounge['lounge_name']?.toString() ??
                        AppStrings.anonymous,
                    bookings: (lounge['bookings_count'] as num?)?.toInt() ?? 0,
                    revenue:
                        '${(lounge['total_revenue'] as num?)?.toDouble().toStringAsFixed(0) ?? '0'} ${AppStrings.priceEgp}',
                    trend: '',
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
