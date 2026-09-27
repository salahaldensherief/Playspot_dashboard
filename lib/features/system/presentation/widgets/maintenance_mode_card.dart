import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../domain/entities/app_status_entity.dart';
import 'stop_confirmation_dialog.dart';

class MaintenanceModeCard extends StatefulWidget {
  final AppStatusEntity appStatus;
  final bool isLoading;
  final Function({
    required bool isMaintenanceMode,
    required String maintenanceMessageAr,
    required String maintenanceMessageEn,
    DateTime? expectedEndTime,
  }) onSave;

  const MaintenanceModeCard({
    super.key,
    required this.appStatus,
    required this.isLoading,
    required this.onSave,
  });

  @override
  State<MaintenanceModeCard> createState() => _MaintenanceModeCardState();
}

class _MaintenanceModeCardState extends State<MaintenanceModeCard> {
  late bool _isMaintenanceMode;
  late TextEditingController _msgArController;
  late TextEditingController _msgEnController;
  DateTime? _expectedEndTime;

  @override
  void initState() {
    super.initState();
    _isMaintenanceMode = widget.appStatus.isMaintenanceMode;
    _msgArController = TextEditingController(text: widget.appStatus.maintenanceMessageAr);
    _msgEnController = TextEditingController(text: widget.appStatus.maintenanceMessageEn);
    _expectedEndTime = widget.appStatus.expectedEndTime;
  }

  @override
  void didUpdateWidget(covariant MaintenanceModeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appStatus != widget.appStatus) {
      _isMaintenanceMode = widget.appStatus.isMaintenanceMode;
      _msgArController.text = widget.appStatus.maintenanceMessageAr;
      _msgEnController.text = widget.appStatus.maintenanceMessageEn;
      _expectedEndTime = widget.appStatus.expectedEndTime;
    }
  }

  @override
  void dispose() {
    _msgArController.dispose();
    _msgEnController.dispose();
    super.dispose();
  }

  Future<void> _handleToggle(bool newValue) async {
    if (newValue && !_isMaintenanceMode) {
      final confirmed = await StopConfirmationDialog.show(context);
      if (confirmed == true) {
        setState(() {
          _isMaintenanceMode = true;
        });
      }
    } else {
      setState(() {
        _isMaintenanceMode = newValue;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expectedEndTime ?? now.add(const Duration(hours: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_expectedEndTime ?? now.add(const Duration(hours: 2))),
      );

      if (pickedTime != null) {
        setState(() {
          _expectedEndTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _submit() {
    widget.onSave(
      isMaintenanceMode: _isMaintenanceMode,
      maintenanceMessageAr: _msgArController.text.trim(),
      maintenanceMessageEn: _msgEnController.text.trim(),
      expectedEndTime: _expectedEndTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = _expectedEndTime != null
        ? intl.DateFormat('yyyy/MM/dd - hh:mm a').format(_expectedEndTime!)
        : AppStrings.unspecified;

    return SectionContainer(
      title: AppStrings.maintenanceModeControl,
      children: [
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: _isMaintenanceMode ? AppColors.danger.withAlpha(20) : AppColors.mutedBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _isMaintenanceMode ? AppColors.danger : AppColors.borderDefault,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isMaintenanceMode ? Icons.build_circle : Icons.check_circle_outline,
                    color: _isMaintenanceMode ? AppColors.danger : AppColors.success,
                    size: 28.r,
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.maintenanceModeSystem,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _isMaintenanceMode
                            ? AppStrings.maintenanceModeActiveDesc
                            : AppStrings.maintenanceModeInactiveDesc,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  StatusBadge(
                    text: _isMaintenanceMode ? AppStrings.active : AppStrings.inactive,
                    color: _isMaintenanceMode ? AppColors.danger : AppColors.success,
                  ),
                  SizedBox(width: 16.w),
                  Switch.adaptive(
                    value: _isMaintenanceMode,
                    activeTrackColor: AppColors.danger,
                    onChanged: _handleToggle,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: AppStrings.maintenanceMsgAr,
                hintText: AppStrings.maintenanceMsgArHint,
                controller: _msgArController,
                maxLines: 2,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: AppTextField(
                label: AppStrings.maintenanceMsgEn,
                hintText: AppStrings.maintenanceMsgEnHint,
                controller: _msgEnController,
                maxLines: 2,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.expectedEndTime,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  InkWell(
                    onTap: _pickDateTime,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.mutedBackground,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.neonBlue, size: 20.r),
                          SizedBox(width: 12.w),
                          Text(
                            formattedDate,
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
                          ),
                          const Spacer(),
                          if (_expectedEndTime != null)
                            IconButton(
                              icon: Icon(Icons.clear, color: AppColors.textSecondary, size: 18.r),
                              onPressed: () => setState(() => _expectedEndTime = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 24.h),
                child: AppButton(
                  text: AppStrings.saveAndUpdateMaintenance,
                  icon: Icons.save_outlined,
                  isLoading: widget.isLoading,
                  backgroundColor: _isMaintenanceMode ? AppColors.danger : AppColors.neonBlue,
                  onPressed: _submit,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
