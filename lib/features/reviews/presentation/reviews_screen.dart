import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../art_core/app_strings.dart';
import '../../../art_core/theme/app_colors.dart';
import '../../../art_core/widgets/app_button.dart';
import '../../../art_core/widgets/app_text.dart';
import '../../../core/responsive/responsive.dart';
import '../../auth/presentation/login/login_cubit.dart';
import '../../auth/presentation/login/login_state.dart';
import '../domain/entities/lounge_review_entity.dart';
import 'reviews_cubit.dart';
import 'reviews_state.dart';
import 'widgets/review_card.dart';
import 'widgets/reviews_pagination_footer.dart';
import 'widgets/reviews_rating_overview_card.dart';

/// Responsive Web Dashboard Screen for viewing customer reviews and ratings for the lounge.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
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
              _buildHeader(context),
              SizedBox(height: 24.h),
              BlocBuilder<ReviewsCubit, ReviewsState>(
                buildWhen: (prev, curr) =>
                    prev.status != curr.status ||
                    prev.reviews != curr.reviews ||
                    prev.page != curr.page,
                builder: (context, state) {
                  if (state.status == ReviewsStatus.loading &&
                      state.reviews.isEmpty) {
                    return _buildLoadingWidget();
                  }

                  if (state.status == ReviewsStatus.failure &&
                      state.reviews.isEmpty) {
                    return _buildErrorWidget(context, state.errorMessage);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReviewsRatingOverviewCard(state: state),
                      SizedBox(height: 24.h),
                      if (state.reviews.isEmpty)
                        _buildEmptyState()
                      else ...[
                        _buildReviewsGridOrList(context, state.reviews),
                        ReviewsPaginationFooter(state: state),
                      ],
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
          icon:
              Icon(Icons.refresh_rounded, color: AppColors.neonBlue, size: 22.r),
        ),
      ],
    );
  }

  Widget _buildReviewsGridOrList(
      BuildContext context, List<LoungeReviewEntity> reviews) {
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
          return ReviewCard(review: reviews[index]);
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return ReviewCard(review: reviews[index]);
      },
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
          Icon(Icons.rate_review_outlined,
              size: 48.r, color: AppColors.textMuted),
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

// Alias for backwards compatibility with legacy imports
typedef LoungeReviewsPage = ReviewsScreen;
