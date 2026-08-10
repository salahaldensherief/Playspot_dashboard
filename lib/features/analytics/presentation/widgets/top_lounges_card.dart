import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../dashboard_cubit.dart';
import '../dashboard_state.dart';

class TopLoungesCard extends StatelessWidget {
  const TopLoungesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.topLounges.isEmpty) {
            return Center(child: AppText.body('No data yet'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.heading(
                AppStrings.topPerformingLounges,
                fontSize: 18.sp,
              ),
              SizedBox(height: 4.h),
              AppText.body(
                AppStrings.topPerformingLoungesSubtitle,
                fontSize: 13.sp,
              ),
              SizedBox(height: 24.h),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.topLounges.length > 5 ? 5 : state.topLounges.length,
                separatorBuilder: (context, index) => Divider(color: AppColors.borderDefault, height: 24.h),
                itemBuilder: (context, index) {
                  final lounge = state.topLounges[index];
                  return _LoungeItem(
                    name: lounge['lounge_name']?.toString() ?? 'Unknown',
                    bookings: (lounge['bookings_count'] as num?)?.toInt() ?? 0,
                    revenue: '${(lounge['total_revenue'] as num?)?.toDouble().toStringAsFixed(0) ?? '0'} ${AppStrings.priceEgp}',
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

class _LoungeItem extends StatelessWidget {
  final String name;
  final int bookings;
  final String revenue;
  final String trend;

  const _LoungeItem({
    required this.name,
    required this.bookings,
    required this.revenue,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            color: AppColors.mutedBackground,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.business, color: AppColors.neonBlue, size: 20.r),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 3,
          child: AppText.subHeading(
            name,
            fontSize: 14.sp,
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body('Bookings', fontSize: 11.sp, color: AppColors.textMuted),
              AppText.body('$bookings', fontSize: 13.sp),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body('Revenue', fontSize: 11.sp, color: AppColors.textMuted),
              AppText.body(revenue, fontSize: 13.sp),
            ],
          ),
        ),
        if (trend.isNotEmpty)
          AppText.subHeading(
            trend,
            color: AppColors.success,
            fontSize: 13.sp,
          ),
      ],
    );
  }
}
