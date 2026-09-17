import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/core/utils/debouncer.dart';

class ShiftFiltersBar extends StatefulWidget {
  final Function(String period, String status, String searchQuery) onFilterChanged;

  const ShiftFiltersBar({
    super.key,
    required this.onFilterChanged,
  });

  @override
  State<ShiftFiltersBar> createState() => _ShiftFiltersBarState();
}

class _ShiftFiltersBarState extends State<ShiftFiltersBar> {
  String _selectedPeriod = 'all'; // 'today', 'week', 'month', 'all'
  String _selectedStatus = 'all'; // 'all', 'open', 'closed', 'approved', 'unapproved'
  final TextEditingController _searchController = TextEditingController();
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 400));

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _notifyParent() {
    widget.onFilterChanged(_selectedPeriod, _selectedStatus, _searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Wrap(
        spacing: 16.w,
        runSpacing: 12.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Period Selector Chips
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(AppStrings.periodFilter, fontSize: 11.sp, color: AppColors.textSecondary),
              SizedBox(height: 6.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPeriodChip(AppStrings.all, 'all'),
                  SizedBox(width: 6.w),
                  _buildPeriodChip(AppStrings.today, 'today'),
                  SizedBox(width: 6.w),
                  _buildPeriodChip(AppStrings.thisWeek, 'week'),
                  SizedBox(width: 6.w),
                  _buildPeriodChip(AppStrings.thisMonth, 'month'),
                ],
              ),
            ],
          ),

          // Status Filter Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(AppStrings.shiftStatusFilter, fontSize: 11.sp, color: AppColors.textSecondary),
              SizedBox(height: 6.h),
              Container(
                height: 38.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: AppColors.mutedBackground,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    dropdownColor: AppColors.cardBackground,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20.r),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(AppStrings.allStatuses)),
                      DropdownMenuItem(value: 'open', child: Text(AppStrings.open)),
                      DropdownMenuItem(value: 'closed', child: Text(AppStrings.close)),
                      DropdownMenuItem(value: 'approved', child: Text(AppStrings.approved)),
                      DropdownMenuItem(value: 'unapproved', child: Text(AppStrings.unapproved)),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedStatus = val);
                        _notifyParent();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          // Search Field
          SizedBox(
            width: 220.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.body(AppStrings.searchCashier, fontSize: 11.sp, color: AppColors.textSecondary),
                SizedBox(height: 6.h),
                SizedBox(
                  height: 38.h,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _searchDebouncer.run(_notifyParent),
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
                    decoration: InputDecoration(
                      hintText: AppStrings.cashierNameHint,
                      hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                      prefixIcon: Icon(Icons.search, size: 18.r, color: AppColors.textSecondary),
                      contentPadding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 10.w),
                      filled: true,
                      fillColor: AppColors.mutedBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.borderDefault),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.neonBlue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final bool isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12.sp)),
      selected: isSelected,
      selectedColor: AppColors.neonBlue,
      backgroundColor: AppColors.mutedBackground,
      side: BorderSide(color: isSelected ? AppColors.neonBlue : AppColors.borderDefault),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0.h),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = value);
          _notifyParent();
        }
      },
    );
  }
}
