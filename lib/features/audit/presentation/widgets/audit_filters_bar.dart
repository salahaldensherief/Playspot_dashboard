import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';

class AuditFiltersBar extends StatefulWidget {
  final String? selectedEntityType;
  final String? selectedSeverity;
  final String? selectedUserId;
  final String? searchBookingId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isExporting;
  final Function({
    String? entityType,
    String? severity,
    String? userId,
    String? bookingId,
    DateTime? startDate,
    DateTime? endDate,
  }) onFilterChanged;
  final VoidCallback onReset;
  final VoidCallback onExportCsv;

  const AuditFiltersBar({
    super.key,
    this.selectedEntityType,
    this.selectedSeverity,
    this.selectedUserId,
    this.searchBookingId,
    this.startDate,
    this.endDate,
    required this.isExporting,
    required this.onFilterChanged,
    required this.onReset,
    required this.onExportCsv,
  });

  @override
  State<AuditFiltersBar> createState() => _AuditFiltersBarState();
}

class _AuditFiltersBarState extends State<AuditFiltersBar> {
  late TextEditingController _bookingIdController;
  late TextEditingController _userController;

  @override
  void initState() {
    super.initState();
    _bookingIdController = TextEditingController(text: widget.searchBookingId ?? '');
    _userController = TextEditingController(text: widget.selectedUserId ?? '');
  }

  @override
  void didUpdateWidget(covariant AuditFiltersBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchBookingId != widget.searchBookingId &&
        _bookingIdController.text != (widget.searchBookingId ?? '')) {
      _bookingIdController.text = widget.searchBookingId ?? '';
    }
    if (oldWidget.selectedUserId != widget.selectedUserId &&
        _userController.text != (widget.selectedUserId ?? '')) {
      _userController.text = widget.selectedUserId ?? '';
    }
  }

  @override
  void dispose() {
    _bookingIdController.dispose();
    _userController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: widget.startDate != null && widget.endDate != null
          ? DateTimeRange(start: widget.startDate!, end: widget.endDate!)
          : null,
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.onFilterChanged(
        entityType: widget.selectedEntityType,
        severity: widget.selectedSeverity,
        userId: widget.selectedUserId,
        bookingId: widget.searchBookingId,
        startDate: picked.start,
        endDate: picked.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Booking ID
          SizedBox(
            width: 180.w,
            child: TextField(
              controller: _bookingIdController,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp),
              decoration: InputDecoration(
                hintText: AppStrings.searchBookingId,
                prefixIcon: Icon(Icons.search_rounded, size: 18.r, color: AppColors.textSecondary),
                contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                filled: true,
                fillColor: AppColors.mutedBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.r),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
              ),
              onSubmitted: (val) {
                widget.onFilterChanged(
                  bookingId: val.trim().isEmpty ? null : val.trim(),
                  entityType: widget.selectedEntityType,
                  severity: widget.selectedSeverity,
                  userId: widget.selectedUserId,
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                );
              },
            ),
          ),

          // Search User
          SizedBox(
            width: 160.w,
            child: TextField(
              controller: _userController,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp),
              decoration: InputDecoration(
                hintText: AppStrings.searchUser,
                prefixIcon: Icon(Icons.person_search_rounded, size: 18.r, color: AppColors.textSecondary),
                contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                filled: true,
                fillColor: AppColors.mutedBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.r),
                  borderSide: const BorderSide(color: AppColors.borderDefault),
                ),
              ),
              onSubmitted: (val) {
                widget.onFilterChanged(
                  userId: val.trim().isEmpty ? null : val.trim(),
                  entityType: widget.selectedEntityType,
                  severity: widget.selectedSeverity,
                  bookingId: widget.searchBookingId,
                  startDate: widget.startDate,
                  endDate: widget.endDate,
                );
              },
            ),
          ),

          // Entity Type Filter
          DropdownButtonHideUnderline(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.mutedBackground,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: DropdownButton<String>(
                value: widget.selectedEntityType ?? 'all',
                dropdownColor: AppColors.cardBackground,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp),
                items: [
                  DropdownMenuItem(value: 'all', child: Text(AppStrings.allEntities)),
                  DropdownMenuItem(value: 'booking', child: Text(AppStrings.bookingEntity)),
                  DropdownMenuItem(value: 'shift', child: Text(AppStrings.shiftEntity)),
                  DropdownMenuItem(value: 'room', child: Text(AppStrings.roomEntity)),
                  DropdownMenuItem(value: 'system', child: Text(AppStrings.systemEntity)),
                  DropdownMenuItem(value: 'lounge', child: Text(AppStrings.loungeEntity)),
                  DropdownMenuItem(value: 'user', child: Text(AppStrings.userEntity)),
                ],
                onChanged: (val) {
                  widget.onFilterChanged(
                    entityType: val == 'all' ? null : val,
                    severity: widget.selectedSeverity,
                    userId: widget.selectedUserId,
                    bookingId: widget.searchBookingId,
                    startDate: widget.startDate,
                    endDate: widget.endDate,
                  );
                },
              ),
            ),
          ),

          // Severity Filter
          DropdownButtonHideUnderline(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.mutedBackground,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: DropdownButton<String>(
                value: widget.selectedSeverity ?? 'all',
                dropdownColor: AppColors.cardBackground,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp),
                items: [
                  DropdownMenuItem(value: 'all', child: Text(AppStrings.allSeverities)),
                  DropdownMenuItem(value: 'critical', child: Text(AppStrings.severityCritical)),
                  DropdownMenuItem(value: 'warning', child: Text(AppStrings.severityWarning)),
                  DropdownMenuItem(value: 'info', child: Text(AppStrings.severityInfo)),
                ],
                onChanged: (val) {
                  widget.onFilterChanged(
                    severity: val == 'all' ? null : val,
                    entityType: widget.selectedEntityType,
                    userId: widget.selectedUserId,
                    bookingId: widget.searchBookingId,
                    startDate: widget.startDate,
                    endDate: widget.endDate,
                  );
                },
              ),
            ),
          ),

          // Period Date Range Picker
          OutlinedButton.icon(
            onPressed: () => _pickDateRange(context),
            icon: Icon(Icons.date_range_rounded, size: 16.r, color: AppColors.neonBlue),
            label: Text(
              widget.startDate != null && widget.endDate != null
                  ? '${widget.startDate!.day}/${widget.startDate!.month} - ${widget.endDate!.day}/${widget.endDate!.month}'
                  : AppStrings.period,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderDefault),
              backgroundColor: AppColors.mutedBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
            ),
          ),

          // Reset Filters Button
          IconButton(
            icon: Icon(Icons.restart_alt_rounded, color: AppColors.textSecondary, size: 20.r),
            tooltip: AppStrings.resetFilters,
            onPressed: () {
              _bookingIdController.clear();
              _userController.clear();
              widget.onReset();
            },
          ),

          // Export CSV Button
          AppButton(
            text: widget.isExporting ? AppStrings.exportingCsv : AppStrings.exportCsv,
            icon: Icons.file_download_outlined,
            isLoading: widget.isExporting,
            variant: AppButtonVariant.outlined,
            onPressed: widget.isExporting ? null : widget.onExportCsv,
          ),
        ],
      ),
    );
  }
}
