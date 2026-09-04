import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../domain/entities/lounge_review_entity.dart';
import '../reviews_cubit.dart';
import '../reviews_state.dart';
import 'star_rating_bar.dart';

/// Clean Web Dashboard Card widget displaying real-time Lounge Reviews and Average Ratings.
class LoungeReviewsCard extends StatelessWidget {
  const LoungeReviewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewsCubit, ReviewsState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.reviews != curr.reviews ||
          prev.averageRating != curr.averageRating,
      builder: (context, state) {
        final reviews = state.reviews;
        final double avgRating = state.averageRating;
        final int totalReviews = reviews.length;

        return Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          color: const Color(0xFFFFB800),
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      AppText.heading(
                        AppStrings.loungeReviews,
                        fontSize: 16.sp,
                      ),
                    ],
                  ),
                  if (state.status == ReviewsStatus.loading && reviews.isEmpty)
                    SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              SizedBox(height: 16.h),

              // Prominent Average Rating Display Header
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.mutedBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(
                  children: [
                    // Score Hero Box
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFFFFB800).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText.subHeading(
                            avgRating.toStringAsFixed(1),
                            fontSize: 28.sp,
                            color: const Color(0xFFFFB800),
                            fontWeight: FontWeight.bold,
                          ),
                          AppText.body(
                            'out of 5.0',
                            fontSize: 10.sp,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),

                    // Average Rating Star Bar & Total Reviews Count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.subHeading(
                            AppStrings.averageRating,
                            fontSize: 14.sp,
                            color: AppColors.textPrimary,
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              StarRatingBar(
                                rating: avgRating,
                                size: 20.r,
                              ),
                              SizedBox(width: 8.w),
                              AppText.body(
                                '(${avgRating.toStringAsFixed(1)})',
                                fontSize: 13.sp,
                                color: const Color(0xFFFFB800),
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          AppText.body(
                            '${AppStrings.totalReviews}: $totalReviews',
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Reviews List / Web Data Table
              if (reviews.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 36.r,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 8.h),
                        AppText.body(
                          AppStrings.noReviewsYet,
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.take(10).length,
                  separatorBuilder: (context, index) =>
                      Divider(color: AppColors.divider, height: 20.h),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return _buildReviewTile(context, review);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewTile(BuildContext context, LoungeReviewEntity review) {
    final String dateFormatted = DateFormat('yyyy-MM-dd • hh:mm a').format(review.createdAt);
    final String initial = (review.userName != null && review.userName?.isNotEmpty == true)
        ? (review.userName ?? 'A')[0].toUpperCase()
        : 'A';

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Avatar / Initials Circle
          CircleAvatar(
            radius: 18.r,
            backgroundColor: AppColors.neonBlue.withValues(alpha: 0.15),
            child: Text(
              initial,
              style: TextStyle(
                color: AppColors.neonBlue,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Customer Name & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText.subHeading(
                      review.userName ?? AppStrings.anonymous,
                      fontSize: 13.sp,
                      color: AppColors.textPrimary,
                    ),
                    AppText.body(
                      dateFormatted,
                      fontSize: 10.sp,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),

                // Star Rating Indicator
                Row(
                  children: [
                    StarRatingBar(
                      rating: review.rating,
                      size: 14.r,
                    ),
                    SizedBox(width: 6.w),
                    AppText.body(
                      '${review.rating.toStringAsFixed(1)} / 5.0',
                      fontSize: 11.sp,
                      color: const Color(0xFFFFB800),
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),

                // Review Comment / Feedback
                if (review.comment != null && review.comment?.trim().isNotEmpty == true) ...[
                  SizedBox(height: 6.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: AppText.body(
                      review.comment ?? '',
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
