import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../../../auth/presentation/login/login_state.dart';
import '../../domain/entities/lounge_review_entity.dart';
import '../reviews_cubit.dart';
import '../reviews_state.dart';
import '../widgets/star_rating_bar.dart';

/// Responsive Web Dashboard Screen for viewing customer reviews and ratings for the lounge.
class LoungeReviewsPage extends StatefulWidget {
  const LoungeReviewsPage({super.key});

  @override
  State<LoungeReviewsPage> createState() => _LoungeReviewsPageState();
}

class _LoungeReviewsPageState extends State<LoungeReviewsPage> {
  @override
  void initState() {
    super.initState();
    _triggerReviewsFetch();
  }

  void _triggerReviewsFetch() {
    final loungeId = context.read<LoginCubit>().state.user?.loungeId;
    if (loungeId != null && loungeId.trim().isNotEmpty) {
      context.read<ReviewsCubit>().startWatchingReviews(loungeId: loungeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (previous, current) =>
          previous.user?.loungeId != current.user?.loungeId,
      listener: (context, state) {
        final loungeId = state.user?.loungeId;
        if (loungeId != null && loungeId.trim().isNotEmpty) {
          context.read<ReviewsCubit>().startWatchingReviews(loungeId: loungeId);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              _buildHeader(context),
              SizedBox(height: 24.h),

              // Main Body Content (Listens to ReviewsCubit)
              BlocBuilder<ReviewsCubit, ReviewsState>(
                builder: (context, state) {
                  if (state.status == ReviewsStatus.loading && state.reviews.isEmpty) {
                    return _buildLoadingWidget();
                  }

                  if (state.status == ReviewsStatus.failure && state.reviews.isEmpty) {
                    return _buildErrorWidget(context, state.errorMessage);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Summary Card
                      _buildRatingOverviewCard(state),
                      SizedBox(height: 24.h),

                      // Reviews List or Empty State
                      if (state.reviews.isEmpty)
                        _buildEmptyState()
                      else
                        _buildReviewsGridOrList(context, state.reviews),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.heading(
              AppStrings.loungeReviews,
              fontSize: 22.sp,
              color: AppColors.textPrimary,
            ),
            SizedBox(height: 4.h),
            AppText.body(
              AppStrings.averageRating,
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        IconButton(
          onPressed: _triggerReviewsFetch,
          tooltip: 'refresh'.tr(),
          icon: Icon(Icons.refresh_rounded, color: AppColors.neonBlue, size: 22.r),
        ),
      ],
    );
  }

  Widget _buildRatingOverviewCard(ReviewsState state) {
    final double avgRating = state.averageRating;
    final int totalReviews = state.reviews.length;

    // Calculate rating distribution
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

  Widget _buildScoreHero(double avgRating, int totalReviews) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB800).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.subHeading(
                avgRating.toStringAsFixed(1),
                fontSize: 36.sp,
                color: const Color(0xFFFFB800),
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
                    AppText.body('$star', fontSize: 11.sp, color: AppColors.textSecondary),
                    SizedBox(width: 2.w),
                    Icon(Icons.star_rounded, size: 12.r, color: const Color(0xFFFFB800)),
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
                    color: const Color(0xFFFFB800),
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

  Widget _buildReviewsGridOrList(BuildContext context, List<LoungeReviewEntity> reviews) {
    if (Responsive.isDesktop(context)) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.r,
          mainAxisSpacing: 16.r,
          mainAxisExtent: 160.h,
        ),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          return _buildReviewCard(reviews[index]);
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return _buildReviewCard(reviews[index]);
      },
    );
  }

  Widget _buildReviewCard(LoungeReviewEntity review) {
    final String dateFormatted = DateFormat('yyyy-MM-dd • hh:mm a').format(review.createdAt);
    final String displayName = (review.userName != null && review.userName?.trim().isNotEmpty == true)
        ? review.userName?.trim() ?? AppStrings.anonymous
        : AppStrings.anonymous;
    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
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
          // Header: User Info & Date
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppColors.neonBlue.withValues(alpha: 0.15),
                backgroundImage: (avatarUrl != null && avatarUrl.trim().isNotEmpty)
                    ? NetworkImage(avatarUrl)
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
                color: const Color(0xFFFFB800),
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Comment Body Container
          if (review.comment != null && review.comment?.trim().isNotEmpty == true)
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

  Widget _buildLoadingWidget() {
    return Container(
      padding: EdgeInsets.all(40.r),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppColors.neonBlue),
            SizedBox(height: 16.h),
            AppText.body('loading'.tr(), color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String? errorMessage) {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 40.r, color: AppColors.danger),
            SizedBox(height: 12.h),
            AppText.body(
              errorMessage ?? AppStrings.actionFailed,
              color: AppColors.danger,
              fontSize: 13.sp,
            ),
            SizedBox(height: 16.h),
            AppButton(
              onPressed: _triggerReviewsFetch,
              text: 'retry'.tr(),
              width: 140.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(48.r),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 48.r, color: AppColors.textMuted),
          SizedBox(height: 12.h),
          AppText.subHeading(
            AppStrings.noReviewsYet,
            color: AppColors.textSecondary,
            fontSize: 14.sp,
          ),
        ],
      ),
    );
  }
}
