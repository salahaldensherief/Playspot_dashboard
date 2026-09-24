import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_state.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/widgets/add_branch_dialog.dart';

class TopBarBranchSwitcher extends StatelessWidget {
  const TopBarBranchSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoungeCubit, LoungeState>(
      buildWhen: (prev, curr) =>
          prev.selectedLoungeId != curr.selectedLoungeId ||
          prev.lounges != curr.lounges ||
          prev.status != curr.status,
      builder: (context, state) {
        final lounges = state.lounges;
        if (lounges.isEmpty) {
          return const SizedBox.shrink();
        }

        final selectedLounge = state.selectedLounge ?? lounges.firstOrNull;
        final selectedName = selectedLounge?.name ?? AppStrings.allBranches;

        // If only 1 lounge, render a sleek non-interactive badge
        if (lounges.length == 1) {
          return Container(
            constraints: BoxConstraints(minHeight: 40.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_rounded,
                  color: AppColors.neonBlue,
                  size: 16.r,
                ),
                SizedBox(width: 8.w),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 150.w),
                  child: Text(
                    selectedName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Multi-branch interactive selector
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showBranchSelectorDialog(context, state),
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              constraints: BoxConstraints(minHeight: 40.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.neonBlue.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonBlue.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: AppColors.neonBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: AppColors.neonBlue,
                      size: 14.r,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 150.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${lounges.length} ${AppStrings.allBranches}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.neonBlue,
                    size: 18.r,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBranchSelectorDialog(BuildContext context, LoungeState state) {
    final loungeCubit = context.read<LoungeCubit>();

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (diagContext) {
        return _BranchPickerDialog(
          lounges: state.lounges,
          selectedLoungeId: state.selectedLoungeId,
          onSelect: (loungeId) {
            loungeCubit.selectLounge(loungeId);
            Navigator.of(diagContext).pop();
          },
          onAddBranch: () {
            Navigator.of(diagContext).pop();
            showDialog<bool>(
              context: context,
              builder: (dialogCtx) => AddBranchDialog(
                onSave: (branchData) => loungeCubit.addBranch(branchData),
              ),
            );
          },
        );
      },
    );
  }
}

class _BranchPickerDialog extends StatefulWidget {
  final List<Lounge> lounges;
  final String? selectedLoungeId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddBranch;

  const _BranchPickerDialog({
    required this.lounges,
    required this.selectedLoungeId,
    required this.onSelect,
    required this.onAddBranch,
  });

  @override
  State<_BranchPickerDialog> createState() => _BranchPickerDialogState();
}

class _BranchPickerDialogState extends State<_BranchPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.lounges.where((l) {
      if (_searchQuery.isEmpty) return true;
      final name = l.name.toLowerCase();
      final city = (l.city ?? '').toLowerCase();
      return name.contains(_searchQuery) || city.contains(_searchQuery);
    }).toList();

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: const BorderSide(color: AppColors.borderDefault),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440.w,
          maxHeight: 520.h,
        ),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.neonBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.account_tree_rounded,
                          color: AppColors.neonBlue,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      AppText.heading(
                        AppStrings.switchBranch,
                        fontSize: 18.sp,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Search field (if more than 3 branches)
              if (widget.lounges.length > 3) ...[
                TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.searchBranches,
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 20.r,
                    ),
                    filled: true,
                    fillColor: AppColors.mutedBackground,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColors.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColors.borderDefault),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColors.neonBlue),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              // Branch list
              Flexible(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.r),
                          child: AppText.body(
                            AppStrings.noBranchesFound,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final branch = filtered[index];
                          final isSelected = branch.id == widget.selectedLoungeId;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onSelect(branch.id),
                              borderRadius: BorderRadius.circular(12.r),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.neonBlue.withValues(alpha: 0.1)
                                      : AppColors.mutedBackground,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.neonBlue
                                        : AppColors.borderDefault,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36.r,
                                      height: 36.r,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.neonBlue.withValues(alpha: 0.2)
                                            : AppColors.cardBackground,
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Icon(
                                        Icons.storefront_rounded,
                                        color: isSelected
                                            ? AppColors.neonBlue
                                            : AppColors.textSecondary,
                                        size: 20.r,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            branch.name,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.neonBlue
                                                  : AppColors.textPrimary,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (branch.city != null &&
                                              (branch.city ?? '').isNotEmpty) ...[
                                            SizedBox(height: 2.h),
                                            Text(
                                              branch.city ?? '',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: EdgeInsets.all(4.r),
                                        decoration: const BoxDecoration(
                                          color: AppColors.neonBlue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14.r,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 16.h),
              AppButton(
                text: AppStrings.addNewBranch,
                icon: Icons.add_rounded,
                variant: AppButtonVariant.outlined,
                onPressed: widget.onAddBranch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
