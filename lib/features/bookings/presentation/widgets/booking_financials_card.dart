import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import '../../domain/entities/booking.dart';

/// Reusable UI Card displaying Financials, Extra items/canteen orders, and Payment status.
class BookingFinancialsCard extends StatefulWidget {
  final Booking booking;
  final TextEditingController? discountController;
  final TextEditingController? reasonController;
  final bool isPercentage;
  final ValueChanged<bool>? onTogglePercentage;
  final ValueChanged<String>? onChanged;

  const BookingFinancialsCard({
    super.key,
    required this.booking,
    this.discountController,
    this.reasonController,
    this.isPercentage = false,
    this.onTogglePercentage,
    this.onChanged,
  });

  @override
  State<BookingFinancialsCard> createState() => _BookingFinancialsCardState();
}

class _BookingFinancialsCardState extends State<BookingFinancialsCard> {
  double _calculateExtrasTotal() {
    if (widget.booking.addonsPrice != null && widget.booking.addonsPrice! > 0) {
      return widget.booking.addonsPrice!;
    }
    double total = 0.0;
    for (final item in widget.booking.extras) {
      final q = (item['quantity'] ?? item['qty'] ?? item['count'] as num?)?.toInt() ?? 1;
      final p = (item['price'] ?? item['unit_price'] ?? item['total_price'] as num?)?.toDouble() ?? 0.0;
      total += q * p;
    }
    if (total == 0.0 && widget.booking.canteenOrders.isNotEmpty) {
      for (final order in widget.booking.canteenOrders) {
        total += (order['total_price'] ?? order['price'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  double get _discountValue {
    if (widget.discountController == null) return 0.0;
    return double.tryParse(widget.discountController!.text) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final extrasTotal = _calculateExtrasTotal();
    final basePrice = (widget.booking.totalPrice - extrasTotal).clamp(0.0, double.infinity);
    final isPaid = widget.booking.paymentStatus == PaymentStatus.paid;

    double calculatedDiscountAmount = 0.0;
    if (_discountValue > 0) {
      calculatedDiscountAmount = widget.isPercentage
          ? (widget.booking.totalPrice * _discountValue / 100)
          : _discountValue;
    } else if ((widget.booking.discountAmount ?? 0) > 0) {
      calculatedDiscountAmount = widget.booking.discountAmount!;
    } else if ((widget.booking.voucherDiscount ?? 0) > 0) {
      calculatedDiscountAmount = widget.booking.voucherDiscount!;
    }

    final finalPrice = (widget.booking.totalPrice - calculatedDiscountAmount).clamp(0.0, double.infinity);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.mutedBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.payments_outlined, color: AppColors.success, size: 20),
                  SizedBox(width: 8.w),
                  AppText.subHeading(
                    AppStrings.financialsAndExtras,
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
              _getPaymentBadge(widget.booking.paymentStatus),
            ],
          ),
          SizedBox(height: 16.h),

          // Price Summary List
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              children: [
                _buildPriceRow(AppStrings.basePrice, '${basePrice.toStringAsFixed(2)} ${AppStrings.egp}'),
                if (extrasTotal > 0) ...[
                  SizedBox(height: 8.h),
                  _buildPriceRow(AppStrings.additionalItems, '${extrasTotal.toStringAsFixed(2)} ${AppStrings.egp}'),
                ],
                if (calculatedDiscountAmount > 0) ...[
                  SizedBox(height: 8.h),
                  _buildPriceRow(
                    AppStrings.discount,
                    '-${calculatedDiscountAmount.toStringAsFixed(2)} ${AppStrings.egp}',
                    color: AppColors.success,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.borderDefault),
                ),
                _buildPriceRow(
                  AppStrings.totalPrice,
                  '${finalPrice.toStringAsFixed(2)} ${AppStrings.egp}',
                  isBold: true,
                  fontSize: 16.sp,
                  color: AppColors.neonBlue,
                ),
              ],
            ),
          ),

          // Detailed Canteen Orders Section
          if (widget.booking.canteenOrders.isNotEmpty) ...[
            SizedBox(height: 16.h),
            AppText.subHeading('طلبات الكافيتريا - Canteen Orders', fontSize: 14.sp),
            SizedBox(height: 8.h),
            ...widget.booking.canteenOrders.map((order) {
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
              if (order['items'] is List) {
                orderItems = (order['items'] as List)
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
                      final name = (item['name'] ?? item['name_ar'] ?? item['name_en'] ?? item['title'] ?? 'صنف').toString();
                      final unitPrice = (item['price'] ?? item['unit_price'] as num?)?.toDouble() ?? 0.0;

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
                            if (unitPrice > 0)
                              AppText.body(
                                '${(quantity * unitPrice).toStringAsFixed(2)} ${AppStrings.egp}',
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
                        alignment: Alignment.centerLeft,
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
          ] else if (widget.booking.extras.isNotEmpty) ...[
            SizedBox(height: 16.h),
            AppText.subHeading(AppStrings.additionalItems, fontSize: 14.sp),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                children: widget.booking.extras.map((item) {
                  final quantity = (item['quantity'] ?? item['qty'] ?? item['count'] as num?)?.toInt() ?? 1;
                  final name = (item['name'] ?? item['name_ar'] ?? item['name_en'] ?? item['title'] ?? AppStrings.addItem).toString();
                  final unitPrice = (item['price'] ?? item['unit_price'] as num?)?.toDouble() ?? 0.0;
                  final totalItemPrice = quantity * unitPrice;

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppText.body(
                            '${quantity}x $name',
                            fontSize: 13.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppText.body(
                          '${totalItemPrice.toStringAsFixed(2)} ${AppStrings.egp}',
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Discount Input Section (if unpaid and controllers provided)
          if (!isPaid && widget.discountController != null && widget.reasonController != null) ...[
            SizedBox(height: 16.h),
            AppText.subHeading(AppStrings.discount, fontSize: 14.sp),
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: AppStrings.discount,
                    controller: widget.discountController!,
                    keyboardType: TextInputType.number,
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => widget.onTogglePercentage?.call(false),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            child: Text(
                              'EGP',
                              style: TextStyle(
                                color: !widget.isPercentage ? AppColors.neonBlue : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => widget.onTogglePercentage?.call(true),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            child: Text(
                              '%',
                              style: TextStyle(
                                color: widget.isPercentage ? AppColors.neonBlue : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onChanged: (val) {
                      setState(() {});
                      widget.onChanged?.call(val);
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    label: AppStrings.discountReason,
                    controller: widget.reasonController!,
                    hintText: 'Reason for audit...',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    double? fontSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.body(
          label,
          fontSize: fontSize ?? 13.sp,
          color: color ?? AppColors.textSecondary,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        AppText.body(
          value,
          fontSize: fontSize ?? 13.sp,
          color: color ?? AppColors.textPrimary,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ],
    );
  }

  Widget _getPaymentBadge(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return StatusBadge.success(AppStrings.paid.toUpperCase());
      case PaymentStatus.refunded:
        return StatusBadge.danger(AppStrings.payouts.toUpperCase());
      case PaymentStatus.unpaid:
        return StatusBadge.warning(AppStrings.unpaid.toUpperCase());
    }
  }
}
