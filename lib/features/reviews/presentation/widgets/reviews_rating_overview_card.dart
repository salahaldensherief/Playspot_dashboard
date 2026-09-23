import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/responsive/responsive.dart';
import '../reviews_state.dart';
import 'star_rating_bar.dart';

class ReviewsRatingOverviewCard extends StatelessWidget {
  final ReviewsState state;

  const ReviewsRatingOverviewCard({super.key, required this.state});

  Widget _buildScoreHero(double avgRating, int totalReviews) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.starRating.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16.r),
            border:
                Border.all(color: AppColors.starRating.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.subHeading(
                avgRating.toStringAsFixed(1),
                fontSize: 36.sp,
                color: AppColors.starRating,
                fontWeight: FontWeight.bold,
              ),
              AppText.body(
                'out of 5.0',
                fontSize: 11.sp,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
        SizedBox(width: 20.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StarRatingBar(rating: avgRating, size: 24.r),
            SizedBox(height: 8.h),
            AppText.subHeading(
              '${AppStrings.totalReviews}: $totalReviews',
              fontSize: 14.sp,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingDistributionBars(Map<int, int> counts, int totalReviews) {
    return Column(
      children: List.generate(5, (index) {
        final star = 5 - index;
        final count = counts[star] ?? 0;
        final double ratio = totalReviews > 0 ? count / totalReviews : 0.0;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Row(
            children: [
              SizedBox(
                width: 40.w,
                child: Row(
                  children: [
                    AppText.body('$star',
                        fontSize: 11.sp, color: AppColors.textSecondary),
                    SizedBox(width: 2.w),
                    Icon(Icons.star_rounded,
                        size: 12.r, color: AppColors.starRating),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8.h,
                    backgroundColor: AppColors.mutedBackground,
                    color: AppColors.starRating,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              SizedBox(
                width: 32.w,
                child: AppText.body(
                  '$count',
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double avgRating = state.averageRating;
    final int totalReviews = state.reviews.length;

    final Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in state.reviews) {
      final star = r.rating.round().clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Responsive(
        mobile: Column(
          children: [
            _buildScoreHero(avgRating, totalReviews),
            SizedBox(height: 20.h),
            _buildRatingDistributionBars(counts, totalReviews),
          ],
        ),
        desktop: Row(
          children: [
            _buildScoreHero(avgRating, totalReviews),
            SizedBox(width: 32.w),
            Container(width: 1.w, height: 120.h, color: AppColors.divider),
            SizedBox(width: 32.w),
            Expanded(child: _buildRatingDistributionBars(counts, totalReviews)),
          ],
        ),
      ),
    );
  }
}
