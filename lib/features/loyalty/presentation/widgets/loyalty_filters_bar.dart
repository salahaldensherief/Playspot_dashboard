import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../../../art_core/widgets/custom_dropdown.dart';
import '../../../auth/presentation/login/login_cubit.dart';
import '../cubit/loyalty_cubit.dart';
import '../cubit/loyalty_state.dart';
import 'adjust_user_points_dialog.dart';

class LoyaltyFiltersBar extends StatefulWidget {
  const LoyaltyFiltersBar({super.key});

  @override
  State<LoyaltyFiltersBar> createState() => _LoyaltyFiltersBarState();
}

class _LoyaltyFiltersBarState extends State<LoyaltyFiltersBar> {
  final TextEditingController _userSearchController = TextEditingController();

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  void _pickDateRange(BuildContext context, LoyaltyCubit cubit) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      cubit.updateFilters(startDate: picked.start, endDate: picked.end);
    }
  }

  void _showAdjustPointsDialog(BuildContext context, LoyaltyCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AdjustUserPointsDialog(
        onAdjust: (userId, pointsDelta, reason) {
          cubit.adjustUserPoints(
            userId: userId,
            pointsDelta: pointsDelta,
            reason: reason,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyCubit = context.read<LoyaltyCubit>();
    final isSuperAdmin = context.watch<LoginCubit>().state.user?.isSuperAdmin ?? false;

    return BlocBuilder<LoyaltyCubit, LoyaltyState>(
      builder: (context, state) {
        final dateLabel = state.startDate != null && state.endDate != null
            ? '${DateFormat('yyyy-MM-dd').format(state.startDate!)} - ${DateFormat('yyyy-MM-dd').format(state.endDate!)}'
            : AppStrings.filterByDate;

        final isArabic = context.locale.languageCode == 'ar';

        final levelItems = ['all', ...state.levels.map((l) => l.id)];
        final statusItems = ['all', 'completed', 'pending'];

        final selectedLevel = (state.selectedLevelId != null &&
                state.selectedLevelId!.isNotEmpty &&
                levelItems.contains(state.selectedLevelId))
            ? state.selectedLevelId!
            : 'all';

        final selectedStatus = (state.selectedReferralStatus != null &&
                state.selectedReferralStatus!.isNotEmpty &&
                statusItems.contains(state.selectedReferralStatus))
            ? state.selectedReferralStatus!
            : 'all';

        return Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Wrap(
            spacing: 16.w,
            runSpacing: 16.h,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              // Date Range Picker Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.filterByDate,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AppButton(
                    onPressed: () => _pickDateRange(context, loyaltyCubit),
                    icon: Icons.date_range_outlined,
                    text: dateLabel,
                    variant: AppButtonVariant.outlined,
                  ),
                ],
              ),

              // Level Filter Dropdown
              SizedBox(
                width: 170.w,
                child: CustomDropdown<String>(
                  label: AppStrings.filterByLevel,
                  value: selectedLevel,
                  items: levelItems,
                  itemLabel: (item) {
                    if (item == 'all') return AppStrings.all;
                    for (final l in state.levels) {
                      if (l.id == item) {
                        return isArabic ? l.nameAr : l.nameEn;
                      }
                    }
                    return AppStrings.all;
                  },
                  onChanged: (val) {
                    loyaltyCubit.updateFilters(levelId: val == 'all' ? '' : val);
                  },
                ),
              ),

              // Referral Status Filter Dropdown
              SizedBox(
                width: 170.w,
                child: CustomDropdown<String>(
                  label: AppStrings.filterByStatus,
                  value: selectedStatus,
                  items: statusItems,
                  itemLabel: (item) {
                    if (item == 'completed') return AppStrings.completed;
                    if (item == 'pending') return AppStrings.pending;
                    return AppStrings.all;
                  },
                  onChanged: (val) {
                    loyaltyCubit.updateFilters(referralStatus: val ?? 'all');
                  },
                ),
              ),

              // User Search Field
              SizedBox(
                width: 220.w,
                child: AppTextField(
                  label: AppStrings.filterByUser,
                  controller: _userSearchController,
                  hintText: AppStrings.userSearchHint,
                  prefixIcon: Icons.search,
                  onChanged: (val) {
                    loyaltyCubit.updateFilters(userId: val);
                  },
                ),
              ),

              // Clear Filters Button
              IconButton(
                onPressed: () {
                  _userSearchController.clear();
                  loyaltyCubit.clearFilters();
                },
                icon: const Icon(Icons.filter_alt_off_outlined, color: AppColors.danger),
                tooltip: AppStrings.resetFilters,
              ),

              // Adjust User Points Button (Super Admin Only)
              if (isSuperAdmin)
                AppButton(
                  text: AppStrings.adjustUserPoints,
                  icon: Icons.edit_attributes_outlined,
                  variant: AppButtonVariant.gradient,
                  onPressed: () => _showAdjustPointsDialog(context, loyaltyCubit),
                ),
            ],
          ),
        );
      },
    );
  }
}
