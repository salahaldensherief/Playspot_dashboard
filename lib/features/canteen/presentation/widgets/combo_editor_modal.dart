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
import '../../domain/entities/canteen_combo_component_entity.dart';
import '../../domain/entities/canteen_combo_entity.dart';

class ComboItemDraft {
  String extraId;
  int quantity;

  ComboItemDraft({required this.extraId, this.quantity = 1});
}

class ComboEditorModal extends StatefulWidget {
  final String loungeId;
  final CanteenComboEntity? initialCombo;
  final List<ExtraEntity> availableExtras;
  final Future<bool> Function(CanteenComboEntity combo) onSave;

  const ComboEditorModal({
    super.key,
    required this.loungeId,
    this.initialCombo,
    required this.availableExtras,
    required this.onSave,
  });

  @override
  State<ComboEditorModal> createState() => _ComboEditorModalState();
}

class _ComboEditorModalState extends State<ComboEditorModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameArController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _descArController;
  late final TextEditingController _descEnController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _availableFromController;
  late final TextEditingController _availableToController;

  late List<ComboItemDraft> _items;
  late List<int> _selectedDays;
  late bool _isActive;
  bool _isSaving = false;

  final List<int> _allDays = const [0, 1, 2, 3, 4, 5, 6];
  List<String> get _dayLabels => [
    'calendar_sunday'.tr(),
    'calendar_monday'.tr(),
    'calendar_tuesday'.tr(),
    'calendar_wednesday'.tr(),
    'calendar_thursday'.tr(),
    'calendar_friday'.tr(),
    'calendar_saturday'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.initialCombo;
    _nameArController = TextEditingController(text: c?.nameAr ?? '');
    _nameEnController = TextEditingController(text: c?.nameEn ?? '');
    _descArController = TextEditingController(text: c?.descriptionAr ?? '');
    _descEnController = TextEditingController(text: c?.descriptionEn ?? '');
    _priceController = TextEditingController(
      text: c != null ? c.price.toStringAsFixed(0) : '',
    );
    _imageUrlController = TextEditingController(text: c?.imageUrl ?? '');
    _availableFromController = TextEditingController(
      text: c?.availableFrom ?? '',
    );
    _availableToController = TextEditingController(text: c?.availableTo ?? '');

    _selectedDays = c?.daysOfWeek != null
        ? List<int>.from(c!.daysOfWeek!)
        : List<int>.from(_allDays);
    _isActive = c?.isActive ?? true;

    if (c != null && c.items.isNotEmpty) {
      _items = c.items
          .map(
            (item) =>
                ComboItemDraft(extraId: item.extraId, quantity: item.quantity),
          )
          .toList();
    } else {
      _items = [];
    }

    _priceController.addListener(_onPriceChanged);
  }

  void _onPriceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _priceController.removeListener(_onPriceChanged);
    _nameArController.dispose();
    _nameEnController.dispose();
    _descArController.dispose();
    _descEnController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _availableFromController.dispose();
    _availableToController.dispose();
    super.dispose();
  }

  ExtraEntity? _findExtra(String id) {
    try {
      return widget.availableExtras.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  double get _separateItemsTotal {
    double total = 0.0;
    for (final item in _items) {
      final extra = _findExtra(item.extraId);
      if (extra != null) {
        total += extra.price * item.quantity;
      }
    }
    return total;
  }

  double get _estimatedCostTotal {
    double total = 0.0;
    for (final item in _items) {
      final extra = _findExtra(item.extraId);
      final cost = extra?.costPrice;
      if (cost != null) {
        total += cost * item.quantity;
      }
    }
    return total;
  }

  double get _bundlePrice =>
      double.tryParse(_priceController.text.trim()) ?? 0.0;

  double? get _profitMargin {
    final cost = _estimatedCostTotal;
    final price = _bundlePrice;
    if (cost <= 0 || price <= 0) return null;
    return price - cost;
  }

  double? get _profitMarginPercent {
    final margin = _profitMargin;
    final price = _bundlePrice;
    if (margin == null || price <= 0) return null;
    return (margin / price) * 100.0;
  }

  double get _savings {
    final sep = _separateItemsTotal;
    final price = _bundlePrice;
    return (sep > price && price > 0) ? (sep - price) : 0.0;
  }

  void _addItem() {
    if (widget.availableExtras.isEmpty) return;
    final firstAvailable = widget.availableExtras.first.id;
    setState(() {
      _items.add(ComboItemDraft(extraId: firstAvailable, quantity: 1));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.comboItemsSelector),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.bundlePrice),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final comboId = widget.initialCombo?.id ?? '';
    final components = _items.map((item) {
      final extra = _findExtra(item.extraId);
      return CanteenComboComponentEntity(
        comboId: comboId,
        extraId: item.extraId,
        quantity: item.quantity,
        extraNameAr: extra?.nameAr,
        extraNameEn: extra?.nameEn,
        extraPrice: extra?.price,
        extraCostPrice: extra?.costPrice,
        extraImageUrl: extra?.imageUrl,
      );
    }).toList();

    final fromTime = _availableFromController.text.trim().isNotEmpty
        ? _availableFromController.text.trim()
        : null;
    final toTime = _availableToController.text.trim().isNotEmpty
        ? _availableToController.text.trim()
        : null;

    final newCombo = CanteenComboEntity(
      id: comboId,
      loungeId: widget.loungeId,
      nameAr: _nameArController.text.trim(),
      nameEn: _nameEnController.text.trim().isNotEmpty
          ? _nameEnController.text.trim()
          : null,
      descriptionAr: _descArController.text.trim().isNotEmpty
          ? _descArController.text.trim()
          : null,
      descriptionEn: _descEnController.text.trim().isNotEmpty
          ? _descEnController.text.trim()
          : null,
      imageUrl: _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : null,
      price: price,
      daysOfWeek: _selectedDays.length == 7 ? null : _selectedDays,
      availableFrom: fromTime,
      availableTo: toTime,
      validFrom: widget.initialCombo?.validFrom,
      validTo: widget.initialCombo?.validTo,
      isActive: _isActive,
      sortOrder: widget.initialCombo?.sortOrder ?? 0,
      items: components,
    );

    final success = await widget.onSave(newCombo);
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
      title: widget.initialCombo != null
          ? AppStrings.editCombo
          : AppStrings.addCombo,
      width: 720.w,
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
            // Row 1: Names
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: AppStrings.comboNameAr,
                    controller: _nameArController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.required
                        : null,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppTextField(
                    label: AppStrings.comboNameEn,
                    controller: _nameEnController,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Row 2: Price & Image URL
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: '${AppStrings.bundlePrice} (${AppStrings.egp})',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.required
                        : null,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppTextField(
                    label: AppStrings.comboImageUrl,
                    controller: _imageUrlController,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Row 3: Descriptions
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: AppStrings.comboDescAr,
                    controller: _descArController,
                    maxLines: 2,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppTextField(
                    label: AppStrings.comboDescEn,
                    controller: _descEnController,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Combo Components Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.subHeading(
                  AppStrings.comboItemsSelector,
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                AppButton(
                  text: AppStrings.addItemToCombo,
                  icon: Icons.add,
                  onPressed: _addItem,
                ),
              ],
            ),
            SizedBox(height: 12.h),

            if (_items.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: AppColors.mutedBackground,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Center(
                  child: AppText.body(
                    AppStrings.addItemToCombo,
                    fontSize: 13.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final itemDraft = _items[index];
                  final currentExtra = _findExtra(itemDraft.extraId);

                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mutedBackground,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                itemDraft.extraId.isNotEmpty &&
                                    widget.availableExtras.any(
                                      (e) => e.id == itemDraft.extraId,
                                    )
                                ? itemDraft.extraId
                                : null,
                            dropdownColor: AppColors.cardBackground,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.sp,
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 8.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(
                                  color: AppColors.borderDefault,
                                ),
                              ),
                            ),
                            items: widget.availableExtras.map((extra) {
                              return DropdownMenuItem<String>(
                                value: extra.id,
                                child: Text(
                                  '${extra.nameAr} (${extra.price.toStringAsFixed(0)} ${AppStrings.egp})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  itemDraft.extraId = val;
                                });
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // Quantity Stepper
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: itemDraft.quantity > 1
                                  ? () => setState(() => itemDraft.quantity--)
                                  : null,
                            ),
                            AppText.body(
                              '${itemDraft.quantity}',
                              fontSize: 14.sp,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                              ),
                              onPressed: () =>
                                  setState(() => itemDraft.quantity++),
                            ),
                          ],
                        ),
                        SizedBox(width: 12.w),

                        // Subtotal
                        if (currentExtra != null)
                          AppText.body(
                            '${(currentExtra.price * itemDraft.quantity).toStringAsFixed(0)} ${AppStrings.egp}',
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),

                        const Spacer(),

                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            SizedBox(height: 20.h),

            // Live Analytics & Financial Calculation Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.body(
                        AppStrings.separateItemsTotal,
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                      AppText.body(
                        '${_separateItemsTotal.toStringAsFixed(0)} ${AppStrings.egp}',
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.body(
                        AppStrings.bundlePrice,
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                      AppText.body(
                        '${_bundlePrice.toStringAsFixed(0)} ${AppStrings.egp}',
                        fontSize: 14.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.body(
                        AppStrings.savingsBadge,
                        fontSize: 13.sp,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: AppText.body(
                          '${_savings.toStringAsFixed(0)} ${AppStrings.egp}',
                          fontSize: 12.sp,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_estimatedCostTotal > 0) ...[
                    SizedBox(height: 6.h),
                    Divider(color: AppColors.borderDefault, height: 1.h),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.body(
                          AppStrings.profitMargin,
                          fontSize: 13.sp,
                          color: AppColors.warning,
                        ),
                        AppText.body(
                          '${(_profitMargin ?? 0).toStringAsFixed(0)} ${AppStrings.egp} (${(_profitMarginPercent ?? 0).toStringAsFixed(1)}%)',
                          fontSize: 13.sp,
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Days of Week Selection
            AppText.subHeading(
              AppStrings.availableDays,
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: List.generate(7, (i) {
                final isSelected = _selectedDays.contains(i);
                return FilterChip(
                  label: Text(_dayLabels[i]),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(i);
                      } else {
                        _selectedDays.remove(i);
                      }
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 16.h),

            // Available Hours (Optional)
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: '${AppStrings.availableHours} (من - مثلاً 14:00)',
                    controller: _availableFromController,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: AppTextField(
                    label: '${AppStrings.availableHours} (إلى - مثلاً 23:00)',
                    controller: _availableToController,
                  ),
                ),
              ],
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
