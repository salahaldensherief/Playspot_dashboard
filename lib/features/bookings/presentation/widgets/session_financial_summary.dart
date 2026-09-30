import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../domain/entities/booking.dart';
import 'session_fact.dart';

class SessionFinancialSummary extends StatelessWidget {
  final Booking booking;
  const SessionFinancialSummary({super.key, required this.booking});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SessionFact(
        label: 'cashier.payment'.tr(),
        value: AppStrings.paymentStatusLabel(booking.paymentStatus.name.tr()),
      ),
      SessionFact(
        label: 'cashier.serverTotal'.tr(),
        value: booking.isOpenEnded
            ? 'cashier.awaitingFinal'.tr()
            : '${booking.totalPrice.toStringAsFixed(2)} ${AppStrings.egp}',
      ),
      SessionFact(
        label: 'cashier.collected'.tr(),
        value: 'cashier.unavailable'.tr(),
      ),
      SessionFact(label: 'cashier.due'.tr(), value: 'cashier.unavailable'.tr()),
      Text('cashier.financeNotice'.tr()),
    ],
  );
}
