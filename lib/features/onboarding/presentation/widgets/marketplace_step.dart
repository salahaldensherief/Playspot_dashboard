import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../../../lounges/presentation/widgets/extra_dialog.dart';
import '../cubit/onboarding_cubit.dart';

class MarketplaceStep extends StatelessWidget {
  final String loungeId;

  const MarketplaceStep({super.key, required this.loungeId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.subHeading(AppStrings.marketplace, fontSize: 18.sp),
        SizedBox(height: 8.h),
        AppText.body(AppStrings.marketplaceSubtitle),
        SizedBox(height: 24.h),
        BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, state) {
            if (state.extras.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.extras.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final extra = state.extras[index];
                return _buildExtraItem(extra);
              },
            );
          },
        ),
        SizedBox(height: 24.h),
        AppButton(
          text: AppStrings.addExtraItem,
          variant: AppButtonVariant.outlined,
          icon: Icons.add,
          onPressed: () => _showAddExtraDialog(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, color: AppColors.textSecondary, size: 48.r),
            SizedBox(height: 16.h),
            AppText.body(AppStrings.noItemsAdded, fontSize: 16.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraItem(dynamic extra) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.neonPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: const Icon(Icons.fastfood, color: AppColors.neonPurple),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subHeading(extra.name),
                AppText.body('${extra.category} • ${extra.price} ${AppStrings.priceEgp}', fontSize: 12.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExtraDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (diagContext) => ExtraDialog(
        loungeId: loungeId,
        onSave: (newExtra) => context.read<OnboardingCubit>().addNewExtra(newExtra),
      ),
    );
  }
}
