import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_dialog.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationDialog extends StatefulWidget {
  final Function(NotificationEntity) onSend;

  const NotificationDialog({super.key, required this.onSend});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleArController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _bodyArController = TextEditingController();
  final _bodyEnController = TextEditingController();
  NotificationType _selectedType = NotificationType.offer;

  @override
  void dispose() {
    _titleArController.dispose();
    _titleEnController.dispose();
    _bodyArController.dispose();
    _bodyEnController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSend(NotificationEntity(
        id: const Uuid().v4(),
        titleAr: _titleArController.text,
        titleEn: _titleEnController.text,
        bodyAr: _bodyArController.text,
        bodyEn: _bodyEnController.text,
        type: _selectedType,
        createdAt: DateTime.now(),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    return AppDialog(
      title: AppStrings.newNotification,
      width: 580.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 16.w),
        AppButton(
          text: AppStrings.newNotification,
          onPressed: _submit,
          icon: Icons.send,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: AppStrings.promoTitleAr,
                    controller: _titleArController,
                    validator: AppValidator.validateRequired,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppTextField(
                    label: AppStrings.promoTitleEn,
                    controller: _titleEnController,
                    validator: AppValidator.validateRequired,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: AppStrings.descriptionArLabel,
              controller: _bodyArController,
              maxLines: 3,
              validator: AppValidator.validateRequired,
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: AppStrings.descriptionEnLabel,
              controller: _bodyEnController,
              maxLines: 3,
              validator: AppValidator.validateRequired,
            ),
            SizedBox(height: 16.h),
            CustomDropdown<NotificationType>(
              label: AppStrings.rewardType,
              value: _selectedType,
              items: NotificationType.values,
              itemLabel: (t) => t.name.toUpperCase(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
