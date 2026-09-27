import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/add_extras_dialog.dart';

class AddBookingExtrasSection extends StatelessWidget {
  final String loungeId;
  final List<Map<String, dynamic>> selectedExtras;
  final ValueChanged<List<Map<String, dynamic>>> onExtrasChanged;

  const AddBookingExtrasSection({
    super.key,
    required this.loungeId,
    required this.selectedExtras,
    required this.onExtrasChanged,
  });

  void _openAddExtrasModal(BuildContext context) {
    AddExtrasDialog.show(
      context,
      bookingId: '',
      loungeId: loungeId,
      onConfirm: (extras, totalCost) {
        onExtrasChanged(extras);
      },
    );
  }

  void _removeExtra(int index) {
    final updated = List<Map<String, dynamic>>.from(selectedExtras);
    updated.removeAt(index);
    onExtrasChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu_rounded, size: 18.r, color: AppColors.neonBlue),
                SizedBox(width: 6.w),
                AppText.body(AppStrings.extras, fontWeight: FontWeight.bold),
              ],
            ),
            InkWell(
              onTap: () => _openAddExtrasModal(context),
              borderRadius: BorderRadius.circular(6.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 16.r, color: AppColors.neonBlue),
                    SizedBox(width: 4.w),
                    AppText.body(
                      AppStrings.addExtrasToSession,
                      fontSize: 12.sp,
                      color: AppColors.neonBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (selectedExtras.isEmpty)
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16.r, color: AppColors.textMuted),
                SizedBox(width: 8.w),
                Expanded(
                  child: AppText.body(
                    'لم يتم إضافة مشروبات أو مأكولات مع الحجز حتى الآن',
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: List.generate(selectedExtras.length, (index) {
              final item = selectedExtras[index];
              final name = item['name_ar'] ?? item['name'] ?? '';
              final qty = item['quantity'] ?? item['qty'] ?? 1;
              final price = (item['price'] ?? item['unit_price'] ?? 0.0) * qty;

              return Chip(
                backgroundColor: AppColors.neonBlue.withValues(alpha: 0.1),
                side: const BorderSide(color: AppColors.neonBlue),
                avatar: CircleAvatar(
                  backgroundColor: AppColors.neonBlue,
                  child: Text(
                    '$qty',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                label: Text(
                  '$name (${price.toStringAsFixed(0)} ${AppStrings.egp})',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 11.sp),
                ),
                deleteIcon: const Icon(Icons.close, size: 14),
                deleteIconColor: AppColors.danger,
                onDeleted: () => _removeExtra(index),
              );
            }),
          ),
      ],
    );
  }
}
