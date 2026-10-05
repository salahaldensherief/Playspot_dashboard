import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../../../art_core/widgets/app_dialog.dart';
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
            if (_formKey.currentState!.validate()) {
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
            _buildTextField(_qArController, AppStrings.questionAr, AppStrings.questionArHint),
            SizedBox(height: 12.h),
            _buildTextField(_aArController, AppStrings.answerAr, AppStrings.answerArHint, maxLines: 3),
            SizedBox(height: 20.h),
            _buildSectionHeader(AppStrings.englishLanguage),
            SizedBox(height: 8.h),
            _buildTextField(_qEnController, AppStrings.questionEn, AppStrings.questionEnHint),
            SizedBox(height: 12.h),
            _buildTextField(_aEnController, AppStrings.answerEn, AppStrings.answerEnHint, maxLines: 3),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_orderController, AppStrings.sortOrderPriority, '0', isNumber: true),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
            filled: true,
            fillColor: AppColors.scaffoldBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          validator: (value) {
            if (!isNumber && (value == null || value.trim().isEmpty)) {
              return AppStrings.fieldRequired;
            }
            return null;
          },
        ),
      ],
    );
  }
}
