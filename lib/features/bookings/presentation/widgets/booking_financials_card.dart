import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/status_badge.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_financials_canteen_orders.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_financials_discount_input.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_financials_extras_list.dart';

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
    double total = 0.0;
    for (final item in widget.booking.extras) {
      final q = (item['quantity'] ?? item['qty'] ?? item['count'] as num?)?.toInt() ?? 1;
      final p = (item['price'] ?? item['unit_price'] ?? item['total_price'] as num?)?.toDouble() ?? 0.0;
      total += q * p;
    }
    if (total == 0.0 && widget.booking.canteenOrders.isNotEmpty) {
      for (final order in widget.booking.canteenOrders) {
        dynamic rawItems = order['items'];
        if (rawItems is String && rawItems.trim().isNotEmpty) {
          try {
            rawItems = jsonDecode(rawItems);
          } catch (_) {}
        }
        if (rawItems is List) {
          for (final item in rawItems) {
            if (item is Map) {
              final q = (item['quantity'] ?? item['qty'] ?? item['count'] as num?)?.toInt() ?? 1;
              final p = (item['price'] ?? item['unit_price'] as num?)?.toDouble() ?? 0.0;
              total += q * p;
            }
          }
        }
        if (total == 0.0) {
          total += (order['total_price'] ?? order['price'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    if (total == 0.0 && widget.booking.addonsPrice != null && (widget.booking.addonsPrice ?? 0) > 0) {
      return widget.booking.addonsPrice ?? 0.0;
    }
    return total;
  }

  double get _discountValue {
    if (widget.discountController == null) return 0.0;
    return double.tryParse(widget.discountController?.text ?? '') ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final extrasTotal = _calculateExtrasTotal();
    final basePrice = (widget.booking.totalPrice - extrasTotal).clamp(0.0, double.infinity);
    final isPaid = widget.booking.paymentStatus == PaymentStatus.paid;

    final voucherDiscount = widget.booking.voucherDiscount ?? 0.0;
    final manualDiscount = (_discountValue > 0)
        ? (widget.isPercentage ? (widget.booking.totalPrice * _discountValue / 100) : _discountValue)
        : (widget.booking.discountAmount ?? 0.0);

    final totalDiscount = voucherDiscount + manualDiscount;
    final finalPrice = (widget.booking.totalPrice - totalDiscount).clamp(0.0, double.infinity);

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
                if (voucherDiscount > 0) ...[
                  SizedBox(height: 8.h),
                  _buildPriceRow(
                    (widget.booking.voucherCode != null && widget.booking.voucherCode!.isNotEmpty)
                        ? '${AppStrings.voucherDiscount} (${widget.booking.voucherCode})'
                        : AppStrings.voucherDiscount,
                    '-${voucherDiscount.toStringAsFixed(2)} ${AppStrings.egp}',
                    color: AppColors.success,
                  ),
                ],
                if (manualDiscount > 0) ...[
                  SizedBox(height: 8.h),
                  _buildPriceRow(
                    (widget.booking.discountReason != null && widget.booking.discountReason!.isNotEmpty)
                        ? '${AppStrings.discount} (${widget.booking.discountReason})'
                        : AppStrings.discount,
                    '-${manualDiscount.toStringAsFixed(2)} ${AppStrings.egp}',
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

          // Detailed Extras Section
          BookingFinancialsExtrasList(extras: widget.booking.extras),

          // Detailed Canteen Orders Section
          BookingFinancialsCanteenOrders(canteenOrders: widget.booking.canteenOrders),

          // Discount Input Section (if unpaid and controllers provided)
          if (!isPaid && widget.discountController != null && widget.reasonController != null)
            BookingFinancialsDiscountInput(
              discountController: widget.discountController!,
              reasonController: widget.reasonController!,
              isPercentage: widget.isPercentage,
              onTogglePercentage: widget.onTogglePercentage,
              onChanged: (val) {
                setState(() {});
                widget.onChanged?.call(val);
              },
            ),
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
