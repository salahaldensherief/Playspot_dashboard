import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
import '../../../../art_core/widgets/app_text_field.dart';
import '../../domain/entities/faq_entity.dart';

class FaqDialog extends StatefulWidget {
  final FaqEntity? faq;
  final ValueChanged<FaqEntity> onSave;

  const FaqDialog({
    super.key,
    this.faq,
    required this.onSave,
  });

  @override
  State<FaqDialog> createState() => _FaqDialogState();
}

class _FaqDialogState extends State<FaqDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _qArController;
  late TextEditingController _aArController;
  late TextEditingController _qEnController;
  late TextEditingController _aEnController;
  late TextEditingController _orderController;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _qArController = TextEditingController(text: widget.faq?.questionAr ?? '');
    _aArController = TextEditingController(text: widget.faq?.answerAr ?? '');
    _qEnController = TextEditingController(text: widget.faq?.questionEn ?? '');
    _aEnController = TextEditingController(text: widget.faq?.answerEn ?? '');
    _orderController = TextEditingController(text: (widget.faq?.sortOrder ?? 0).toString());
    _isActive = widget.faq?.isActive ?? true;
  }

  @override
  void dispose() {
    _qArController.dispose();
    _aArController.dispose();
    _qEnController.dispose();
    _aEnController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final bool isEdit = widget.faq != null;

    return AppDialog(
      title: isEdit ? AppStrings.editFaq : AppStrings.addFaq,
      icon: isEdit ? Icons.edit_note : Icons.quiz_outlined,
      width: 650.w,
      actions: [
        AppButton(
          text: AppStrings.cancel,
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 12.w),
        AppButton(
          text: isEdit ? AppStrings.saveChanges : AppStrings.addFaq,
          variant: AppButtonVariant.gradient,
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final newFaq = FaqEntity(
                id: widget.faq?.id ?? '',
                questionAr: _qArController.text.trim(),
                answerAr: _aArController.text.trim(),
                questionEn: _qEnController.text.trim(),
                answerEn: _aEnController.text.trim(),
                sortOrder: int.tryParse(_orderController.text.trim()) ?? 0,
                isActive: _isActive,
              );
              widget.onSave(newFaq);
              Navigator.pop(context);
            }
          },
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader(AppStrings.arabicLanguage),
            SizedBox(height: 8.h),
            AppTextField(
              controller: _qArController,
              label: AppStrings.questionAr,
              hintText: AppStrings.questionArHint,
              validator: (value) => (value == null || value.trim().isEmpty) ? AppStrings.fieldRequired : null,
            ),
            SizedBox(height: 12.h),
            AppTextField(
              controller: _aArController,
              label: AppStrings.answerAr,
              hintText: AppStrings.answerArHint,
              maxLines: 3,
              validator: (value) => (value == null || value.trim().isEmpty) ? AppStrings.fieldRequired : null,
            ),
            SizedBox(height: 20.h),
            _buildSectionHeader(AppStrings.englishLanguage),
            SizedBox(height: 8.h),
            AppTextField(
              controller: _qEnController,
              label: AppStrings.questionEn,
              hintText: AppStrings.questionEnHint,
              validator: (value) => (value == null || value.trim().isEmpty) ? AppStrings.fieldRequired : null,
            ),
            SizedBox(height: 12.h),
            AppTextField(
              controller: _aEnController,
              label: AppStrings.answerEn,
              hintText: AppStrings.answerEnHint,
              maxLines: 3,
              validator: (value) => (value == null || value.trim().isEmpty) ? AppStrings.fieldRequired : null,
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _orderController,
                    label: AppStrings.sortOrderPriority,
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.activeFaq, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp)),
                      Switch(
                        value: _isActive,
                        activeTrackColor: AppColors.neonBlue,
                        onChanged: (val) {
                          setState(() {
                            _isActive = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, fontSize: 14.sp),
    );
  }
}
