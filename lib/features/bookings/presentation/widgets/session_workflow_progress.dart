import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../domain/entities/booking.dart';

/// Presentation of persisted lifecycle state; never advances the booking.
class SessionWorkflowProgress extends StatelessWidget {
  final Booking booking;
  const SessionWorkflowProgress({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final stage = switch (booking.status) {
      BookingStatus.inProgress => 1,
      BookingStatus.completed => 2,
      _ => 0,
    };
    final settled =
        booking.status == BookingStatus.completed &&
        booking.paymentStatus == PaymentStatus.paid;
    final labels = [
      'cashier.stageBooking'.tr(),
      'cashier.stagePlay'.tr(),
      'cashier.stageSettlement'.tr(),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: i == stage
                  ? OperationsTokens.selected
                  : OperationsTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: i == stage
                    ? OperationsTokens.accent
                    : OperationsTokens.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (i < stage || settled)
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: OperationsTokens.accent,
                  )
                else
                  Text('${i + 1}', style: OperationsTokens.label),
                const SizedBox(width: 6),
                Text(
                  labels[i],
                  style: OperationsTokens.label.copyWith(
                    color: i == stage ? OperationsTokens.accent : null,
                    fontWeight: i == stage ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
