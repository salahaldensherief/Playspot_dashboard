import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

class CanteenItemsDetailsBox extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double? totalPrice;
  final String? note;

  const CanteenItemsDetailsBox({
    super.key,
    required this.items,
    this.totalPrice,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Separate combo parents, combo components, and standard items
    final List<Map<String, dynamic>> comboParents = [];
    final Map<String, List<Map<String, dynamic>>> comboChildren = {};
    final List<Map<String, dynamic>> standardItems = [];

    for (final item in items) {
      final lineKind = item['line_kind']?.toString() ?? 'item';
      final comboId = item['combo_id']?.toString();
      final comboLineId = item['combo_line_id']?.toString();

      if (lineKind == 'combo_parent') {
        comboParents.add(item);
      } else if (lineKind == 'combo_component') {
        final parentKey = comboLineId ?? comboId ?? 'unknown';
        comboChildren.putIfAbsent(parentKey, () => []).add(item);
      } else if (comboId != null && comboId.isNotEmpty) {
        // Fallback for combo items without explicit line_kind
        comboParents.add(item);
      } else {
        standardItems.add(item);
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu_rounded, size: 14.r, color: AppColors.success),
              SizedBox(width: 6.w),
              AppText.subHeading(
                AppStrings.canteenOrderDetails,
                fontSize: 12.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          if (note != null && (note?.trim().isNotEmpty ?? false)) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.note_alt_rounded, size: 12.r, color: AppColors.warning),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: AppText.body(
                      'ملاحظة: ${note ?? ''}',
                      fontSize: 10.sp,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 8.h),

          // Render Combo Parents with nested components
          ...comboParents.map((parent) {
            final parentKey = parent['combo_line_id']?.toString() ??
                parent['id']?.toString() ??
                parent['combo_id']?.toString() ??
                'unknown';
            final children = comboChildren[parentKey] ?? [];

            return _ExpandableComboRow(
              parent: parent,
              children: children,
            );
          }),

          // Render Standard Items
          ...standardItems.map((item) {
            final name = item['name_ar'] ?? item['name'] ?? item['name_en'] ?? item['item_name'] ?? AppStrings.item;
            final qty = item['quantity'] ?? item['qty'] ?? 1;
            final price = (item['price'] ?? item['unit_price'] as num?)?.toDouble() ?? 0.0;
            final isLowStock = item['is_low_stock'] == true;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: AppText.body(
                            '${qty}x',
                            fontSize: 11.sp,
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: AppText.body(
                            name,
                            fontSize: 12.sp,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isLowStock) ...[
                          SizedBox(width: 6.w),
                          _buildLowStockBadge(),
                        ],
                      ],
                    ),
                  ),
                  if (price > 0)
                    AppText.body(
                      '${(price * (qty as num)).toStringAsFixed(0)} ${AppStrings.egp}',
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                ],
              ),
            );
          }),

          // Order Total Section
          if (totalPrice != null && (totalPrice ?? 0) > 0) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Divider(color: AppColors.borderDefault, height: 1.h),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.body(
                  AppStrings.extrasTotal,
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: AppText.subHeading(
                    '${(totalPrice ?? 0).toStringAsFixed(0)} ${AppStrings.egp}',
                    fontSize: 12.sp,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildLowStockBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 10.r, color: AppColors.error),
          SizedBox(width: 3.w),
          AppText.body(
            AppStrings.lowStockWarning,
            fontSize: 9.sp,
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}

class _ExpandableComboRow extends StatefulWidget {
  final Map<String, dynamic> parent;
  final List<Map<String, dynamic>> children;

  const _ExpandableComboRow({
    required this.parent,
    required this.children,
  });

  @override
  State<_ExpandableComboRow> createState() => _ExpandableComboRowState();
}

class _ExpandableComboRowState extends State<_ExpandableComboRow> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final parentName = widget.parent['name_ar'] ??
        widget.parent['name'] ??
        widget.parent['name_en'] ??
        AppStrings.combosTab;
    final parentQty = widget.parent['quantity'] ?? widget.parent['qty'] ?? 1;
    final parentPrice =
        (widget.parent['price'] ?? widget.parent['unit_price'] as num?)?.toDouble() ?? 0.0;

    final hasAnyLowStock = widget.children.any((c) => c['is_low_stock'] == true) ||
        widget.parent['is_low_stock'] == true;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent Row Header
          InkWell(
            onTap: widget.children.isNotEmpty
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: AppText.body(
                      '${parentQty}x',
                      fontSize: 11.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.fastfood_rounded, size: 14.r, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: AppText.body(
                      parentName,
                      fontSize: 12.sp,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasAnyLowStock) ...[
                    CanteenItemsDetailsBox._buildLowStockBadge(),
                    SizedBox(width: 8.w),
                  ],
                  if (parentPrice > 0)
                    AppText.body(
                      '${(parentPrice * (parentQty as num)).toStringAsFixed(0)} ${AppStrings.egp}',
                      fontSize: 12.sp,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  if (widget.children.isNotEmpty) ...[
                    SizedBox(width: 4.w),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16.r,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Nested Components (Indented)
          if (_isExpanded && widget.children.isNotEmpty) ...[
            Divider(color: AppColors.borderDefault, height: 1.h),
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: 24.w,
                end: 8.w,
                top: 4.h,
                bottom: 6.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children.map((child) {
                  final cName = child['name_ar'] ??
                      child['name'] ??
                      child['name_en'] ??
                      AppStrings.item;
                  final cQty = child['quantity'] ?? child['qty'] ?? 1;
                  final isChildLow = child['is_low_stock'] == true;

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: Row(
                      children: [
                        Icon(Icons.subdirectory_arrow_left_rounded,
                            size: 12.r, color: AppColors.textMuted),
                        SizedBox(width: 4.w),
                        AppText.body(
                          '${cQty}x $cName',
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        if (isChildLow) ...[
                          SizedBox(width: 6.w),
                          CanteenItemsDetailsBox._buildLowStockBadge(),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
