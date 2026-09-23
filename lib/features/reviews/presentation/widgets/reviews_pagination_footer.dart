import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import '../reviews_cubit.dart';
import '../reviews_state.dart';

class ReviewsPaginationFooter extends StatelessWidget {
  final ReviewsState state;

  const ReviewsPaginationFooter({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final loungeId = context.read<LoginCubit>().state.user?.loungeId;
    if (loungeId == null || loungeId.isEmpty || state.totalCount == 0) {
      return const SizedBox.shrink();
    }

    final startIndex = (state.page - 1) * state.pageSize + 1;
    final endIndex =
        (startIndex + state.reviews.length - 1).clamp(0, state.totalCount);

    return Container(
      margin: EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$startIndex - $endIndex / ${state.totalCount}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
          Row(
            children: [
              AppButton(
                text: AppStrings.back,
                variant: AppButtonVariant.outlined,
                fontSize: 12.sp,
                onPressed: state.hasPreviousPage
                    ? () => context.read<ReviewsCubit>().fetchReviewsPage(
                          loungeId: loungeId,
                          page: state.page - 1,
                          pageSize: state.pageSize,
                        )
                    : null,
              ),
              SizedBox(width: 12.w),
              Text(
                '${state.page} / ${state.totalPages == 0 ? 1 : state.totalPages}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(width: 12.w),
              AppButton(
                text: AppStrings.next,
                variant: AppButtonVariant.outlined,
                fontSize: 12.sp,
                onPressed: state.hasNextPage
                    ? () => context.read<ReviewsCubit>().fetchReviewsPage(
                          loungeId: loungeId,
                          page: state.page + 1,
                          pageSize: state.pageSize,
                        )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
