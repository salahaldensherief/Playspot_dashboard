import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../../../art_core/widgets/custom_dropdown.dart';
import '../../domain/entities/pricing_rule_entity.dart';
import '../pricing_cubit.dart';
import '../pricing_state.dart';
import 'pricing_confirmation_modal.dart';
import 'pricing_weekly_preview_bar.dart';

class PricingRuleEditorDrawer extends StatefulWidget {
  final String loungeId;
  final PricingRuleEntity? existingRule;
  final VoidCallback onClose;

  const PricingRuleEditorDrawer({
    super.key,
    required this.loungeId,
    this.existingRule,
    required this.onClose,
  });

  @override
  State<PricingRuleEditorDrawer> createState() =>
      _PricingRuleEditorDrawerState();
}

class _PricingRuleEditorDrawerState extends State<PricingRuleEditorDrawer> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _valueController;

  String _ruleType = 'peak';
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  TimeOfDay _startTime = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  DateTime? _startDate;
  DateTime? _endDate;
  String _adjustmentType = 'multiplier';

  @override
  void initState() {
    super.initState();
    final r = widget.existingRule;
    _nameArController = TextEditingController(text: r?.nameAr ?? 'ساعات الذروة');
    _nameEnController =
        TextEditingController(text: r?.nameEn ?? 'Peak Hours Pricing');
    _valueController = TextEditingController(
      text: r != null ? r.adjustmentValue.toString() : '1.2',
    );

    if (r != null) {
      _ruleType = r.ruleType;
      _selectedDays = List<int>.from(r.daysOfWeek);
      _startTime = _parseTimeOfDay(r.startTime);
      _endTime = _parseTimeOfDay(r.endTime);
      _startDate = r.startDate;
      _endDate = r.endDate;
      _adjustmentType = r.adjustmentType;
    }
  }

  TimeOfDay _parseTimeOfDay(String str) {
    if (str.isEmpty) return const TimeOfDay(hour: 0, minute: 0);
    final parts = str.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  bool get _isOvernight {
    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin = _endTime.hour * 60 + _endTime.minute;
    return endMin <= startMin;
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _onSaveAttempt() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (_) => PricingConfirmationModal(
        affectedRoomsCount: 5,
        onConfirm: _executeSave,
      ),
    );
  }

  void _executeSave() {
    final rule = PricingRuleEntity(
      id: widget.existingRule?.id ?? '',
      loungeId: widget.loungeId,
      nameAr: _nameArController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      ruleType: _ruleType,
      daysOfWeek: _selectedDays,
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      startDate: _startDate,
      endDate: _endDate,
      adjustmentType: _adjustmentType,
      adjustmentValue: double.tryParse(_valueController.text.trim()) ?? 1.0,
      createdAt: widget.existingRule?.createdAt ?? DateTime.now(),
    );

    context.read<PricingCubit>().saveRule(rule, loungeId: widget.loungeId).then((success) {
      if (success && mounted) {
        widget.onClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480.w,
      height: double.infinity,
      color: AppColors.cardBackground,
      padding: EdgeInsets.all(20.r),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingRule == null
                      ? AppStrings.addPricingRule
                      : AppStrings.editPricingRule,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            Divider(color: AppColors.borderDefault, height: 24.h),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rule Name Arabic / English
                    AppTextField(
                      controller: _nameArController,
                      label: AppStrings.ruleNameAr,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? AppStrings.fieldRequired
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _nameEnController,
                      label: AppStrings.ruleNameEn,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? AppStrings.fieldRequired
                          : null,
                    ),
                    SizedBox(height: 16.h),

                    // Rule Type
                    CustomDropdown<String>(
                      label: AppStrings.ruleType,
                      value: _ruleType,
                      items: const ['peak', 'off_peak', 'standard', 'custom'],
                      itemLabel: (type) {
                        switch (type) {
                          case 'peak':
                            return AppStrings.peakHours;
                          case 'off_peak':
                            return AppStrings.offPeakHours;
                          case 'standard':
                            return AppStrings.standardHours;
                          case 'custom':
                          default:
                            return AppStrings.customRule;
                        }
                      },
                      onChanged: (v) {
                        if (v != null) setState(() => _ruleType = v);
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Days Chips
                    Text(
                      AppStrings.daysOfWeek,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: List.generate(7, (idx) {
                        final dayNum = idx + 1;
                        final isSelected = _selectedDays.contains(dayNum);
                        const labels = ['إث', 'ثلا', 'أرب', 'خم', 'جم', 'سب', 'أح'];
                        return ChoiceChip(
                          label: Text(labels[idx]),
                          selected: isSelected,
                          selectedColor: AppColors.neonBlue,
                          backgroundColor: AppColors.mutedBackground,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                          ),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _selectedDays.add(dayNum);
                              } else {
                                if (_selectedDays.length > 1) {
                                  _selectedDays.remove(dayNum);
                                }
                              }
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 16.h),

                    // Time From / To Pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final tod = await showTimePicker(
                                context: context,
                                initialTime: _startTime,
                              );
                              if (tod != null) {
                                setState(() => _startTime = tod);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: AppStrings.startTimeLabel,
                                border: const OutlineInputBorder(),
                              ),
                              child: Text(
                                _startTime.format(context),
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final tod = await showTimePicker(
                                context: context,
                                initialTime: _endTime,
                              );
                              if (tod != null) {
                                setState(() => _endTime = tod);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: AppStrings.endTimeLabel,
                                border: const OutlineInputBorder(),
                              ),
                              child: Text(
                                _endTime.format(context),
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Overnight Warning
                    if (_isOvernight) ...[
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(25),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: AppColors.warning, size: 18.r),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                AppStrings.overnightWarning,
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 16.h),

                    // Date Validity Range
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final dt = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (dt != null) {
                                setState(() => _startDate = dt);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: AppStrings.startDate,
                                border: const OutlineInputBorder(),
                              ),
                              child: Text(
                                _startDate != null
                                    ? DateFormat('yyyy-MM-dd').format(_startDate!)
                                    : 'دائم',
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final dt = await showDatePicker(
                                context: context,
                                initialDate: _endDate ??
                                    DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (dt != null) {
                                setState(() => _endDate = dt);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: AppStrings.endDate,
                                border: const OutlineInputBorder(),
                              ),
                              child: Text(
                                _endDate != null
                                    ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                    : 'بدون نهاية',
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Adjustment Type & Value
                    CustomDropdown<String>(
                      label: AppStrings.adjustmentType,
                      value: _adjustmentType,
                      items: const ['multiplier', 'percentage', 'fixed'],
                      itemLabel: (type) {
                        switch (type) {
                          case 'multiplier':
                            return AppStrings.multiplier;
                          case 'percentage':
                            return AppStrings.percentage;
                          case 'fixed':
                          default:
                            return AppStrings.fixedRate;
                        }
                      },
                      onChanged: (v) {
                        if (v != null) setState(() => _adjustmentType = v);
                      },
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _valueController,
                      label: _adjustmentType == 'multiplier'
                          ? 'قيمة المضاعِف (مثال: 1.2)'
                          : _adjustmentType == 'percentage'
                              ? 'النسبة المئوية % (مثال: 15)'
                              : 'السعر الثابت بالجنية (مثال: 80)',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v == null || double.tryParse(v) == null
                          ? AppStrings.fieldRequired
                          : null,
                    ),
                    SizedBox(height: 20.h),

                    // Weekly Hourly Preview Bar
                    PricingWeeklyPreviewBar(
                      selectedDays: _selectedDays,
                      startTime: _formatTimeOfDay(_startTime),
                      endTime: _formatTimeOfDay(_endTime),
                      ruleType: _ruleType,
                    ),
                    SizedBox(height: 20.h),

                    // Conflicting Rules Section
                    BlocBuilder<PricingCubit, PricingState>(
                      builder: (context, state) {
                        if (state.conflictingRules.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final conflict = state.conflictingRules.first;
                        return Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withAlpha(25),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.danger),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      color: AppColors.danger, size: 20.r),
                                  SizedBox(width: 8.w),
                                  Text(
                                    AppStrings.conflictingRules,
                                    style: TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'تتعارض مع: ${conflict.nameAr} (${conflict.startTime} - ${conflict.endTime})',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11.sp,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              AppButton(
                                text: AppStrings.openConflictingRule,
                                icon: Icons.open_in_new_rounded,
                                variant: AppButtonVariant.outlined,
                                onPressed: () {
                                  // Open conflicting rule into editor
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: AppStrings.cancel,
                    variant: AppButtonVariant.outlined,
                    onPressed: widget.onClose,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppButton(
                    text: AppStrings.save,
                    backgroundColor: AppColors.neonBlue,
                    onPressed: _onSaveAttempt,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
