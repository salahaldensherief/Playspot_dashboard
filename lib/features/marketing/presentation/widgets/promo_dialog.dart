import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import '../../domain/entities/promo_entity.dart';
import 'promo_form_section.dart';
import 'design_style_section.dart';

class PromoDialog extends StatefulWidget {
  final PromoEntity promo;
  final Function(PromoEntity)? onSave;

  const PromoDialog({super.key, required this.promo, this.onSave});

  @override
  State<PromoDialog> createState() => _PromoDialogState();
}

class _PromoDialogState extends State<PromoDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final List<List<Color>> _colorTemplates = [
    [AppColors.neonPurple, AppColors.neonBlue],
    [Colors.orange, Colors.red],
    [Colors.green, Colors.teal],
    [Colors.blue, Colors.indigo],
  ];

  int _selectedTemplate = 0;
  String _selectedIcon = 'Flash';
  String _selectedDeepLink = 'Specific Room';

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.promo.iconKey;
    _selectedDeepLink = widget.promo.deepLink ?? 'Specific Room';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
       if (widget.onSave != null) {
         // Create updated promo from fields
         // This is a simplified version as PromoDialog didn't have all controllers yet
         widget.onSave!(widget.promo);
       }
       Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 600.w,
        padding: EdgeInsets.all(32.r),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PromoFormSection(
                  selectedDeepLink: _selectedDeepLink,
                  onDeepLinkChanged: (v) => setState(() => _selectedDeepLink = v!),
                ),
                SizedBox(height: 24.h),
                DesignStyleSection(
                  colorTemplates: _colorTemplates,
                  selectedTemplate: _selectedTemplate,
                  onTemplateSelected: (index) => setState(() => _selectedTemplate = index),
                  selectedIcon: _selectedIcon,
                  onIconChanged: (v) => setState(() => _selectedIcon = v!),
                ),
                SizedBox(height: 32.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: AppStrings.cancel,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 16.w),
                    AppButton(
                      text: AppStrings.saveChanges,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
