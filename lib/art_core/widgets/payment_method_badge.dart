import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';

/// Reusable badge displaying payment method with appropriate icon and localized text.
class PaymentMethodBadge extends StatelessWidget {
  final String? paymentMethod;
  final bool isCash;
  final bool compact;

  const PaymentMethodBadge({
    super.key,
    this.paymentMethod,
    this.isCash = false,
    this.compact = false,
  });

  factory PaymentMethodBadge.fromBookingPaymentMethod(
    String? method, {
    Key? key,
    bool compact = false,
  }) {
    final cleanMethod = method?.trim().toLowerCase() ?? '';
    final isCashMethod = cleanMethod == 'cash' ||
        cleanMethod == 'cash_payment' ||
        cleanMethod == 'cod';
    return PaymentMethodBadge(
      key: key,
      paymentMethod: method,
      isCash: isCashMethod,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final clean = (paymentMethod ?? '').trim().toLowerCase();

    final Color badgeColor;
    final IconData badgeIcon;
    final String label;

    if (isCash || clean == 'cash' || clean == 'cash_payment') {
      badgeColor = AppColors.warning;
      badgeIcon = Icons.payments_outlined;
      label = AppStrings.paymentMethodCash;
    } else if (clean == 'manual_transfer' || clean == 'wallet' || clean.contains('wallet')) {
      badgeColor = AppColors.neonBlue;
      badgeIcon = Icons.account_balance_wallet_outlined;
      label = AppStrings.paymentMethodWallet;
    } else if (clean == 'instapay' || clean.contains('insta')) {
      badgeColor = AppColors.neonPurple;
      badgeIcon = Icons.send_to_mobile_rounded;
      label = AppStrings.paymentMethodInstapay;
    } else if (clean == 'card' || clean == 'credit_card' || clean == 'debit_card') {
      badgeColor = AppColors.success;
      badgeIcon = Icons.credit_card_outlined;
      label = AppStrings.paymentMethodCard;
    } else if (clean.isNotEmpty) {
      badgeColor = AppColors.textSecondary;
      badgeIcon = Icons.payment_outlined;
      label = paymentMethod!;
    } else {
      badgeColor = AppColors.warning;
      badgeIcon = Icons.payments_outlined;
      label = AppStrings.paymentMethodCash;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8.w : 10.w,
        vertical: compact ? 3.h : 5.h,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: compact ? 12.r : 14.r, color: badgeColor),
          SizedBox(width: 5.w),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: badgeColor,
              fontSize: compact ? 10.sp : 11.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
