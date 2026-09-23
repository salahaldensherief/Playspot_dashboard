import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';

class BookingFinancialsCanteenOrders extends StatelessWidget {
  final List<dynamic> canteenOrders;

  const BookingFinancialsCanteenOrders({
    super.key,
    required this.canteenOrders,
  });

  @override
  Widget build(BuildContext context) {
    if (canteenOrders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        AppText.subHeading('طلبات الكافيتريا - Canteen Orders', fontSize: 14.sp),
        SizedBox(height: 8.h),
        ...canteenOrders.map((order) {
          final orderId = order['id']?.toString() ?? '';
          final note = order['note']?.toString();
          final orderTotal = (order['total_price'] as num?)?.toDouble() ?? 0.0;
          final createdAtRaw = order['created_at']?.toString();
          String timeFormatted = '';
          if (createdAtRaw != null) {
            final dt = DateTime.tryParse(createdAtRaw);
            if (dt != null) timeFormatted = DateFormat('hh:mm a').format(dt);
          }

          List<Map<String, dynamic>> orderItems = [];
          dynamic rawItems = order['items'];
          if (rawItems is String && rawItems.trim().isNotEmpty) {
            try {
              rawItems = jsonDecode(rawItems);
            } catch (_) {}
          }
          if (rawItems is List) {
            orderItems = rawItems
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }

          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (timeFormatted.isNotEmpty || orderId.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.body(
                        'طلب #${orderId.length > 6 ? orderId.substring(0, 6) : orderId}',
                        fontSize: 11.sp,
                        color: AppColors.neonBlue,
                        fontWeight: FontWeight.bold,
                      ),
                      if (timeFormatted.isNotEmpty)
                        AppText.body(timeFormatted, fontSize: 11.sp, color: AppColors.textMuted),
                    ],
                  ),
                  SizedBox(height: 6.h),
                ],
                ...orderItems.map((item) {
                  final quantity = (item['quantity'] ?? item['qty'] ?? item['count'] as num?)?.toInt() ?? 1;
                  final rawName = item['name_ar'] ?? item['name_en'] ?? item['name'] ?? item['title'] ?? item['item_name'];
                  final name = (rawName != null && rawName.toString().trim().isNotEmpty && rawName.toString().trim() != 'null')
                      ? rawName.toString().trim()
                      : 'صنف';
                  final unitPrice = (item['unit_price'] ?? item['price'] as num?)?.toDouble() ?? 0.0;
                  final itemTotal = (item['total_price'] as num?)?.toDouble() ?? (unitPrice * quantity);

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.body(
                          '${quantity}x $name',
                          fontSize: 12.sp,
                          color: AppColors.textPrimary,
                        ),
                        if (itemTotal > 0)
                          AppText.body(
                            '${itemTotal.toStringAsFixed(2)} ${AppStrings.egp}',
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                  );
                }),
                if (note != null && note.trim().isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  AppText.body(
                    'ملاحظة: $note',
                    fontSize: 11.sp,
                    color: AppColors.warning,
                  ),
                ],
                if (orderTotal > 0) ...[
                  SizedBox(height: 4.h),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppText.body(
                      'الإجمالي: ${orderTotal.toStringAsFixed(2)} ${AppStrings.egp}',
                      fontSize: 11.sp,
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
