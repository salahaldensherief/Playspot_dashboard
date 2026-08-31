import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'package:play_spot_dashboard/core/utils/permission_extension.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/extra_entity.dart';

class ExtraDialog extends StatefulWidget {
  final String loungeId;
  final ExtraEntity? extra;
  final Function(ExtraEntity)? onSave;

  const ExtraDialog({
    super.key, 
    required this.loungeId, 
    this.extra,
    this.onSave,
  });

  @override
  State<ExtraDialog> createState() => _ExtraDialogState();
}

class _ExtraDialogState extends State<ExtraDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _priceController;
  late TextEditingController _stockQuantityController;
  late TextEditingController _minStockAlertController;
  String _selectedCategory = 'Drinks';
  bool _trackStock = false;

  @override
  void initState() {
    super.initState();
    _nameArController = TextEditingController(text: widget.extra?.nameAr);
    _nameEnController = TextEditingController(text: widget.extra?.nameEn);
    _priceController = TextEditingController(text: widget.extra?.price.toString());
    _stockQuantityController = TextEditingController(text: (widget.extra?.stockQuantity ?? 0).toString());
    _minStockAlertController = TextEditingController(text: (widget.extra?.minStockAlert ?? 5).toString());
    _selectedCategory = widget.extra?.category ?? 'Drinks';
    _trackStock = widget.extra?.trackStock ?? false;
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _minStockAlertController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final extra = ExtraEntity(
        id: widget.extra?.id ?? const Uuid().v4(),
        loungeId: widget.loungeId,
        nameAr: _nameArController.text,
        nameEn: _nameEnController.text,
        name: _nameEnController.text, // For compatibility
        price: double.tryParse(_priceController.text) ?? 0,
        category: _selectedCategory,
        isOutOfStock: widget.extra?.isOutOfStock ?? false,
        trackStock: _trackStock,
        stockQuantity: int.tryParse(_stockQuantityController.text) ?? 0,
        minStockAlert: int.tryParse(_minStockAlertController.text) ?? 5,
      );

      if (widget.onSave != null) {
        widget.onSave!(extra);
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canEditPrice = context.hasPermission('menu_edit_prices');

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 450.w,
        padding: EdgeInsets.all(32.r),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.heading(
                widget.extra == null ? AppStrings.addExtraItem : AppStrings.editItem, 
                fontSize: 24.sp
              ),
              SizedBox(height: 24.h),
              AppTextField(
                label: AppStrings.nameAr,
                hintText: "الاسم بالعربية",
                controller: _nameArController,
                validator: AppValidator.validateRequired,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: AppStrings.nameEn,
                hintText: "Item Name (English)",
                controller: _nameEnController,
                validator: AppValidator.validateRequired,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: AppStrings.priceEgp,
                hintText: AppStrings.priceHint,
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: AppValidator.validateNumber,
                enabled: canEditPrice,
              ),
              SizedBox(height: 16.h),
              CustomDropdown<String>(
                label: AppStrings.category,
                value: _selectedCategory,
                items: const ['Drinks', 'Snacks', 'Services', 'Others'],
                itemLabel: (s) {
                  switch (s) {
                    case 'Drinks': return AppStrings.drinks;
                    case 'Snacks': return AppStrings.snacks;
                    case 'Services': return AppStrings.services;
                    default: return AppStrings.others;
                  }
                },
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              SizedBox(height: 24.h),
              Divider(color: AppColors.divider),
              SizedBox(height: 16.h),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: AppText.body(AppStrings.trackStock),
                value: _trackStock,
                activeColor: AppColors.neonBlue,
                onChanged: (val) => setState(() => _trackStock = val),
              ),
              if (_trackStock) ...[
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: AppStrings.stockQuantity,
                        controller: _stockQuantityController,
                        keyboardType: TextInputType.number,
                        validator: AppValidator.validateNumber,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: AppTextField(
                        label: AppStrings.lowStockThreshold,
                        controller: _minStockAlertController,
                        keyboardType: TextInputType.number,
                        validator: AppValidator.validateNumber,
                      ),
                    ),
                  ],
                ),
              ],
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
                    text: widget.extra == null ? AppStrings.addItem : AppStrings.updateItem,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
