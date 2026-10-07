import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import '../../../domain/entities/activity_type_entity.dart';

class ActivityTypeDialog extends StatefulWidget {
  final ActivityTypeEntity? activity;
  final Future<ActivityTypeEntity?> Function(ActivityTypeEntity) onSave;

  const ActivityTypeDialog({
    super.key,
    this.activity,
    required this.onSave,
  });

  @override
  State<ActivityTypeDialog> createState() => _ActivityTypeDialogState();
}

class _ActivityTypeDialogState extends State<ActivityTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _labelController;
  late final TextEditingController _iconController;
  late final TextEditingController _sortController;

  late String _category;
  late String _pricingModel;
  late bool _requiresScreen;
  late bool _requiresControllers;
  bool _isSaving = false;
  bool _saveFailed = false;

  static const _categories = <String>[
    'console',
    'pc',
    'vr',
    'simulator',
    'table_sport',
    'board_game',
    'arcade',
    'entertainment',
    'other',
  ];

  static const _pricingModels = <String>[
    'single_multi_hour',
    'per_room_hour',
  ];

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    _nameController = TextEditingController(text: activity?.name ?? '');
    _labelController = TextEditingController(text: activity?.label ?? '');
    _iconController = TextEditingController(
      text: activity?.iconName ?? 'sports_esports',
    );
    _sortController = TextEditingController(
      text: (activity?.sortOrder ?? 0).toString(),
    );
    _category = activity?.category ?? 'other';
    _pricingModel = activity?.pricingModel ?? 'per_room_hour';
    _requiresScreen = activity?.requiresScreen ?? false;
    _requiresControllers = activity?.requiresControllers ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _labelController.dispose();
    _iconController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });

    ActivityTypeEntity? saved;
    try {
      saved = await widget.onSave(
      ActivityTypeEntity(
        id: widget.activity?.id ?? '',
        name: _nameController.text.trim().toLowerCase().replaceAll(' ', '_'),
        label: _labelController.text.trim(),
        sortOrder: int.tryParse(_sortController.text.trim()) ?? 0,
        category: _category,
        iconName: _iconController.text.trim().isEmpty
            ? 'category'
            : _iconController.text.trim(),
        pricingModel: _pricingModel,
        requiresScreen: _requiresScreen,
        requiresControllers: _requiresControllers,
      ),
      );
    } catch (_) {
      saved = null;
    }
    if (!mounted) return;
    if (saved != null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isSaving = false;
        _saveFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.activity == null
          ? AppStrings.addNewActivity
          : AppStrings.editActivity,
      width: 620.w,
      showCloseIcon: !_isSaving,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: AppStrings.save,
          icon: Icons.save_outlined,
          onPressed: _isSaving ? null : _submit,
          isLoading: _isSaving,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_saveFailed)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(
                  AppStrings.actionFailed,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: AppStrings.activityKey,
                    controller: _nameController,
                    hintText: 'table_tennis',
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                        ? AppStrings.fieldRequired
                        : null,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppTextField(
                    label: AppStrings.activityLabel,
                    controller: _labelController,
                    hintText: 'Table Tennis',
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                        ? AppStrings.fieldRequired
                        : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: CustomDropdown<String>(
                    label: AppStrings.activityCategory,
                    value: _categories.contains(_category)
                        ? _category
                        : 'other',
                    items: _categories,
                    itemLabel: (value) => value.replaceAll('_', ' '),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomDropdown<String>(
                    label: AppStrings.activityPricingModel,
                    value: _pricingModels.contains(_pricingModel)
                        ? _pricingModel
                        : 'per_room_hour',
                    items: _pricingModels,
                    itemLabel: (value) => value.replaceAll('_', ' '),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _pricingModel = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: AppStrings.activityIconKey,
                    controller: _iconController,
                    hintText: 'sports_tennis',
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppTextField(
                    label: AppStrings.sortOrder,
                    controller: _sortController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.neonBlue,
              title: Text(
                AppStrings.requiresScreen,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              value: _requiresScreen,
              onChanged: (value) => setState(() => _requiresScreen = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.neonBlue,
              title: Text(
                AppStrings.requiresControllers,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              value: _requiresControllers,
              onChanged: (value) =>
                  setState(() => _requiresControllers = value),
            ),
          ],
        ),
      ),
    );
  }
}
