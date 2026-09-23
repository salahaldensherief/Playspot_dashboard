import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_cached_image.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import '../../domain/entities/lounge_review_entity.dart';
import 'star_rating_bar.dart';

class ReviewCard extends StatelessWidget {
  final LoungeReviewEntity review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final String dateFormatted =
        DateFormat('yyyy-MM-dd • hh:mm a').format(review.createdAt);
    final String displayName =
        (review.userName != null && review.userName?.trim().isNotEmpty == true)
            ? review.userName?.trim() ?? AppStrings.anonymous
            : AppStrings.anonymous;
    final String initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
    final String? avatarUrl = review.userAvatarUrl;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.neonBlue.withValues(alpha: 0.15),
                backgroundImage:
                    (avatarUrl != null && avatarUrl.trim().isNotEmpty)
                        ? AppCachedImage.provider(avatarUrl)
                        : null,
                child: (avatarUrl == null || avatarUrl.trim().isEmpty)
                    ? Text(
                        initial,
                        style: TextStyle(
                          color: AppColors.neonBlue,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.subHeading(
                      displayName,
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
              ),
              StarRatingBar(rating: review.rating, size: 14.r),
              SizedBox(width: 4.w),
              AppText.body(
                review.rating.toStringAsFixed(1),
                fontSize: 11.sp,
                color: AppColors.starRating,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (review.comment != null &&
              review.comment?.trim().isNotEmpty == true)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.mutedBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: SingleChildScrollView(
                  child: AppText.body(
                    review.comment?.trim() ?? '',
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            AppText.body(
              AppStrings.reviewComment,
              fontSize: 11.sp,
              color: AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}
