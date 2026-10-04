import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import '../../../lounges/domain/entities/extra_entity.dart';
import '../../domain/entities/canteen_combo_entity.dart';
import '../../domain/entities/upsell_rule_entity.dart';

class TriggerTemplateItem {
  final String key;
  final String title;
  final String description;

  const TriggerTemplateItem({
    required this.key,
    required this.title,
    required this.description,
  });
}

class UpsellRuleEditorModal extends StatefulWidget {
  final String loungeId;
  final UpsellRuleEntity? initialRule;
  final List<ExtraEntity> availableExtras;
  final List<CanteenComboEntity> availableCombos;
  final Future<bool> Function(UpsellRuleEntity rule) onSave;

  const UpsellRuleEditorModal({
    super.key,
    required this.loungeId,
    this.initialRule,
    required this.availableExtras,
    required this.availableCombos,
    required this.onSave,
  });

  @override
  State<UpsellRuleEditorModal> createState() => _UpsellRuleEditorModalState();
}

class _UpsellRuleEditorModalState extends State<UpsellRuleEditorModal> {
  final _formKey = GlobalKey<FormState>();

  List<TriggerTemplateItem> get _templates => [
    TriggerTemplateItem(
      key: 'session_minutes_elapsed',
      title: AppStrings.triggerSessionMinutes,
      description: 'upsell_elapsed_description'.tr(),
    ),
    TriggerTemplateItem(
      key: 'cart_contains_category',
      title: AppStrings.triggerCartCategory,
      description: 'upsell_cart_description'.tr(),
    ),
    TriggerTemplateItem(
      key: 'session_start',
      title: AppStrings.triggerSessionStart,
      description: 'upsell_start_description'.tr(),
    ),
    TriggerTemplateItem(
      key: 'time_of_day',
      title: AppStrings.triggerTimeOfDay,
      description: 'upsell_hours_description'.tr(),
    ),
  ];

  late String _selectedTrigger;
  late final TextEditingController _minutesController;
  late final TextEditingController _categoryController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _discountController;
  late final TextEditingController _maxImpressionsController;
  late final TextEditingController _priorityController;

  bool _isSuggestingCombo = false;
  String? _selectedExtraId;
  String? _selectedComboId;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRule;

    _selectedTrigger = r?.triggerType ?? 'session_minutes_elapsed';
    final params = r?.triggerParams ?? {};

    _minutesController = TextEditingController(
      text: params['minutes']?.toString() ?? '45',
    );
    _categoryController = TextEditingController(
      text: params['category']?.toString() ?? 'snacks',
    );
    _startTimeController = TextEditingController(
      text: params['start_time']?.toString() ?? '18:00',
    );
    _endTimeController = TextEditingController(
      text: params['end_time']?.toString() ?? '23:00',
    );
    _discountController = TextEditingController(
      text: r?.discountPercent != null
          ? r!.discountPercent!.toStringAsFixed(0)
          : '',
    );
    _maxImpressionsController = TextEditingController(
      text: r != null ? r.maxImpressionsPerBooking.toString() : '2',
    );
    _priorityController = TextEditingController(
      text: r != null ? r.priority.toString() : '100',
    );

    _isSuggestingCombo = r?.suggestComboId != null;
    _selectedExtraId = r?.suggestExtraId;
    _selectedComboId = r?.suggestComboId;

    if (_selectedExtraId == null && _selectedComboId == null) {
      if (widget.availableExtras.isNotEmpty) {
        _selectedExtraId = widget.availableExtras.first.id;
      } else if (widget.availableCombos.isNotEmpty) {
        _isSuggestingCombo = true;
        _selectedComboId = widget.availableCombos.first.id;
      }
    }

    _isActive = r?.isActive ?? true;
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _categoryController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _discountController.dispose();
    _maxImpressionsController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildTriggerParams() {
    switch (_selectedTrigger) {
      case 'session_minutes_elapsed':
        return {'minutes': int.tryParse(_minutesController.text.trim()) ?? 45};
      case 'cart_contains_category':
        return {'category': _categoryController.text.trim().toLowerCase()};
      case 'time_of_day':
        return {
          'start_time': _startTimeController.text.trim(),
          'end_time': _endTimeController.text.trim(),
        };
      case 'session_start':
      default:
        return {};
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isSuggestingCombo &&
        (_selectedExtraId == null || _selectedExtraId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.selectExtra),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isSuggestingCombo &&
        (_selectedComboId == null || _selectedComboId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noCombosFound),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final ruleId = widget.initialRule?.id ?? '';
    final discount = double.tryParse(_discountController.text.trim());
    final maxImp = int.tryParse(_maxImpressionsController.text.trim()) ?? 2;
    final priority = int.tryParse(_priorityController.text.trim()) ?? 100;

    final newRule = UpsellRuleEntity(
      id: ruleId,
      loungeId: widget.loungeId,
      triggerType: _selectedTrigger,
      triggerParams: _buildTriggerParams(),
      suggestExtraId: !_isSuggestingCombo ? _selectedExtraId : null,
      suggestComboId: _isSuggestingCombo ? _selectedComboId : null,
      discountPercent: discount,
      maxImpressionsPerBooking: maxImp,
      priority: priority,
      isActive: _isActive,
      isCombo: _isSuggestingCombo,
    );

    final success = await widget.onSave(newRule);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return AppDialog(
      title: widget.initialRule != null
          ? AppStrings.editUpsellRule
          : AppStrings.addUpsellRule,
      width: 680.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: AppStrings.save,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ready-made Trigger Template Selector
            AppText.subHeading(
              AppStrings.triggerTemplate,
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 8.h),
            DropdownButtonFormField<String>(
              initialValue: _selectedTrigger,
              dropdownColor: AppColors.cardBackground,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 12.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: AppColors.borderDefault),
                ),
              ),
              items: _templates.map((tpl) {
                return DropdownMenuItem<String>(
                  value: tpl.key,
                  child: Text(tpl.title),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedTrigger = val);
                }
              },
            ),
            SizedBox(height: 16.h),

            // Dynamic Parameters by Selected Template
            if (_selectedTrigger == 'session_minutes_elapsed') ...[
              AppTextField(
                label: 'upsell_elapsed_minutes'.tr(),
                controller: _minutesController,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.required
                    : null,
              ),
              SizedBox(height: 16.h),
            ] else if (_selectedTrigger == 'cart_contains_category') ...[
              AppTextField(
                label: 'upsell_cart_category_hint'.tr(),
                controller: _categoryController,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.required
                    : null,
              ),
              SizedBox(height: 16.h),
            ] else if (_selectedTrigger == 'time_of_day') ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'upsell_start_time_hint'.tr(),
                      controller: _startTimeController,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppTextField(
                      label: 'upsell_end_time_hint'.tr(),
                      controller: _endTimeController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],

            // Target Suggestion Type: Extra vs Combo
            AppText.subHeading(
              AppStrings.suggestedItemOrCombo,
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                ChoiceChip(
                  label: Text(AppStrings.singleItemsTab),
                  selected: !_isSuggestingCombo,
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  onSelected: (val) {
                    if (val) setState(() => _isSuggestingCombo = false);
                  },
                ),
                SizedBox(width: 12.w),
                ChoiceChip(
                  label: Text(AppStrings.combosTab),
                  selected: _isSuggestingCombo,
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  onSelected: (val) {
                    if (val) setState(() => _isSuggestingCombo = true);
                  },
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Dropdown to pick specific Item or Combo
            if (!_isSuggestingCombo) ...[
              DropdownButtonFormField<String>(
                initialValue:
                    _selectedExtraId != null &&
                        widget.availableExtras.any(
                          (e) => e.id == _selectedExtraId,
                        )
                    ? _selectedExtraId
                    : null,
                dropdownColor: AppColors.cardBackground,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: AppColors.borderDefault),
                  ),
                ),
                items: widget.availableExtras.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.id,
                    child: Text(
                      '${e.nameAr} (${e.price.toStringAsFixed(0)} ${AppStrings.egp})',
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedExtraId = val),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                initialValue:
                    _selectedComboId != null &&
                        widget.availableCombos.any(
                          (c) => c.id == _selectedComboId,
                        )
                    ? _selectedComboId
                    : null,
                dropdownColor: AppColors.cardBackground,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: AppColors.borderDefault),
                  ),
                ),
                items: widget.availableCombos.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(
                      '${c.nameAr} (${c.price.toStringAsFixed(0)} ${AppStrings.egp})',
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedComboId = val),
              ),
            ],
            SizedBox(height: 16.h),

            // Additional Discount & Max Impressions
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: AppStrings.discountPercentOptional,
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: AppTextField(
                    label: AppStrings.maxImpressions,
                    controller: _maxImpressionsController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Priority
            AppTextField(
              label: 'upsell_priority_hint'.tr(
                args: [(AppStrings.priority).toString()],
              ),
              controller: _priorityController,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.h),

            // Active Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: AppText.body(
                AppStrings.activeStatus,
                fontSize: 14.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              value: _isActive,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _isActive = val),
            ),
          ],
        ),
      ),
    );
  }
}
