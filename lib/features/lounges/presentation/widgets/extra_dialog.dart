import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_button.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_image_picker.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
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
  String _selectedCategory = 'drinks';
  bool _trackStock = false;

  Uint8List? _imageBytes;
  String? _imageName;
  String? _currentImageUrl;
  bool _isUploading = false;

  static const List<String> _validCategories = [
    'drinks',
    'hot_drinks',
    'cold_drinks',
    'food',
    'snacks',
    'services',
    'others'
  ];

  @override
  void initState() {
    super.initState();
    _nameArController = TextEditingController(text: widget.extra?.nameAr);
    _nameEnController = TextEditingController(text: widget.extra?.nameEn);
    _priceController = TextEditingController(text: widget.extra?.price.toString());
    _stockQuantityController = TextEditingController(text: (widget.extra?.stockQuantity ?? 0).toString());
    _minStockAlertController = TextEditingController(text: (widget.extra?.minStockAlert ?? 5).toString());
    
    final rawCat = widget.extra?.category.toLowerCase().trim() ?? 'drinks';
    _selectedCategory = _validCategories.contains(rawCat) ? rawCat : 'drinks';
    _trackStock = widget.extra?.trackStock ?? false;
    _currentImageUrl = widget.extra?.imageUrl;
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    String? finalImageUrl = _currentImageUrl;

    if (_imageBytes != null && _imageName != null) {
      try {
        final uploadedUrl = await sl<StorageService>().uploadExtraImage(
          _imageBytes!,
          _imageName!,
          widget.loungeId,
        );
        finalImageUrl = uploadedUrl;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في رفع الصورة: $e'), backgroundColor: AppColors.danger),
          );
          setState(() {
            _isUploading = false;
          });
          return;
        }
      }
    }

    final stockQty = int.tryParse(_stockQuantityController.text) ?? 0;
    final isOutOfStock = (_trackStock && stockQty <= 0) || (widget.extra?.isOutOfStock ?? false);

    final extra = ExtraEntity(
      id: widget.extra?.id ?? const Uuid().v4(),
      loungeId: widget.loungeId,
      nameAr: _nameArController.text,
      nameEn: _nameEnController.text,
      name: _nameEnController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      category: _selectedCategory.toLowerCase().trim(),
      isOutOfStock: isOutOfStock,
      imageUrl: finalImageUrl,
      trackStock: _trackStock,
      stockQuantity: stockQty,
      minStockAlert: int.tryParse(_minStockAlertController.text) ?? 5,
    );

    if (widget.onSave != null) {
      widget.onSave!(extra);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canEditPrice = context.hasPermission('menu_edit_prices');

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480.w,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(28.r),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.heading(
                  widget.extra == null ? AppStrings.addExtraItem : AppStrings.editItem, 
                  fontSize: 22.sp
                ),
                SizedBox(height: 20.h),
                AppImagePicker(
                  label: 'صورة المنتج / Product Image',
                  initialImageUrl: _currentImageUrl,
                  height: 120.h,
                  onImageSelected: (bytes, name) {
                    setState(() {
                      _imageBytes = bytes;
                      _imageName = name;
                    });
                  },
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  label: AppStrings.nameAr,
                  hintText: AppStrings.nameAr,
                  controller: _nameArController,
                  validator: AppValidator.validateRequired,
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  label: AppStrings.nameEn,
                  hintText: AppStrings.nameEn,
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
                  items: _validCategories,
                  itemLabel: (s) {
                    switch (s) {
                      case 'drinks':
                        return AppStrings.drinks;
                      case 'hot_drinks':
                        return 'Hot Drinks | مشروبات ساخنة';
                      case 'cold_drinks':
                        return 'Cold Drinks | مشروبات باردة';
                      case 'food':
                        return 'Food | مأكولات';
                      case 'snacks':
                        return AppStrings.snacks;
                      case 'services':
                        return AppStrings.services;
                      default:
                        return AppStrings.others;
                    }
                  },
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                SizedBox(height: 20.h),
                const Divider(color: AppColors.divider),
                SizedBox(height: 12.h),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: AppText.body(AppStrings.trackStock),
                  value: _trackStock,
                  activeThumbColor: AppColors.neonBlue,
                  onChanged: (val) => setState(() => _trackStock = val),
                ),
                if (_trackStock) ...[
                  SizedBox(height: 12.h),
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
                SizedBox(height: 28.h),
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
                      isLoading: _isUploading,
                      onPressed: _isUploading ? null : _submit,
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
