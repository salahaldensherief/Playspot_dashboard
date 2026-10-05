import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../domain/entities/loyalty_level_entity.dart';

class EditLevelDialog extends StatefulWidget {
  final LoyaltyLevelEntity level;
  final ValueChanged<LoyaltyLevelEntity> onSave;

  const EditLevelDialog({
    super.key,
    required this.level,
    required this.onSave,
  });

  @override
  State<EditLevelDialog> createState() => _EditLevelDialogState();
}

class _EditLevelDialogState extends State<EditLevelDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _minPointsController;
  late TextEditingController _multiplierController;

  @override
  void initState() {
    super.initState();
    _minPointsController = TextEditingController(text: '${widget.level.minPoints}');
    _multiplierController = TextEditingController(text: '${widget.level.multiplier}');
  }

  @override
  void dispose() {
    _minPointsController.dispose();
    _multiplierController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final minPts = int.tryParse(_minPointsController.text) ?? widget.level.minPoints;
      final mult = double.tryParse(_multiplierController.text) ?? widget.level.multiplier;

      final updated = LoyaltyLevelEntity(
        id: widget.level.id,
        nameAr: widget.level.nameAr,
        nameEn: widget.level.nameEn,
        minPoints: minPts,
        multiplier: mult,
        userCount: widget.level.userCount,
        colorHex: widget.level.colorHex,
      );

      widget.onSave(updated);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return AppDialog(
      title: '${AppStrings.editLevel}: ${widget.level.nameAr}',
      icon: Icons.military_tech_rounded,
      width: 440.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: AppStrings.saveChanges,
          onPressed: _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Min Points
            AppTextField(
              controller: _minPointsController,
              label: AppStrings.minPoints,
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return AppStrings.fieldRequired;
                if (int.tryParse(val) == null) return AppStrings.invalidNumber;
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // Level Multiplier
            AppTextField(
              controller: _multiplierController,
              label: AppStrings.levelMultiplier,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return AppStrings.fieldRequired;
                if (double.tryParse(val) == null) return AppStrings.invalidNumber;
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
