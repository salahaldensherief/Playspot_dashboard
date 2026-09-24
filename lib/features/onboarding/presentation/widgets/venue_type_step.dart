import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';

class VenueTypeStep extends StatelessWidget {
  final bool isChain;
  final ValueChanged<bool> onTypeChanged;
  final TextEditingController brandNameController;
  final TextEditingController branchesCountController;
  final TextEditingController branchNameController;

  const VenueTypeStep({
    super.key,
    required this.isChain,
    required this.onTypeChanged,
    required this.brandNameController,
    required this.branchesCountController,
    required this.branchNameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading(
          AppStrings.venueTypeStepTitle,
          fontSize: 20.sp,
          color: AppColors.textPrimary,
        ),
        SizedBox(height: 6.h),
        AppText.body(
          AppStrings.venueTypeStepSubtitle,
          fontSize: 14.sp,
          color: AppColors.textSecondary,
        ),
        SizedBox(height: 24.h),

        // Cards Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 550;
            final cards = [
              _buildTypeCard(
                title: AppStrings.singleVenue,
                description: AppStrings.singleVenueDesc,
                icon: Icons.storefront_rounded,
                isSelected: !isChain,
                onTap: () => onTypeChanged(false),
              ),
              if (isNarrow) SizedBox(height: 16.h) else SizedBox(width: 16.w),
              _buildTypeCard(
                title: AppStrings.multiBranchChain,
                description: AppStrings.multiBranchChainDesc,
                icon: Icons.account_tree_rounded,
                isSelected: isChain,
                onTap: () => onTypeChanged(true),
              ),
            ];

            if (isNarrow) {
              return Column(children: cards);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                cards[1],
                Expanded(child: cards[2]),
              ],
            );
          },
        ),

        // Multi-Branch Additional Details Section
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isChain
              ? Container(
                  margin: EdgeInsets.only(top: 24.h),
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: AppColors.mutedBackground.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.neonBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.neonBlue,
                            size: 20.r,
                          ),
                          SizedBox(width: 8.w),
                          AppText.heading(
                            AppStrings.multiBranchChain,
                            fontSize: 16.sp,
                            color: AppColors.neonBlue,
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      AppTextField(
                        label: AppStrings.brandName,
                        hintText: AppStrings.brandNameHint,
                        controller: brandNameController,
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: AppTextField(
                              label: AppStrings.branchesCount,
                              hintText: AppStrings.branchesCountHint,
                              controller: branchesCountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              label: AppStrings.branchName,
                              hintText: AppStrings.branchNameHint,
                              controller: branchNameController,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(minHeight: 140.h),
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.neonBlue.withValues(alpha: 0.08)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? AppColors.neonBlue : AppColors.borderDefault,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.neonBlue.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.neonBlue.withValues(alpha: 0.2)
                          : AppColors.mutedBackground,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? AppColors.neonBlue
                          : AppColors.textSecondary,
                      size: 24.r,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24.r,
                    height: 24.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.neonBlue : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.neonBlue
                            : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16.r,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              AppText.heading(
                title,
                fontSize: 16.sp,
                color: isSelected ? AppColors.neonBlue : AppColors.textPrimary,
              ),
              SizedBox(height: 6.h),
              AppText.body(
                description,
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
