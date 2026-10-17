import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../../art_core/widgets/app_button.dart';
import '../../domain/entities/booking.dart';
import '../cubit/booking_cubit.dart';
import 'start_session_button.dart';
import 'manual_payment_verification_dialog.dart';
import 'session_live_clock.dart';

class CashierSessionTile extends StatelessWidget {
  final Booking booking;
  final bool selected;
  final VoidCallback onSelect;
  const CashierSessionTile({
    super.key,
    required this.booking,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final paid = booking.paymentStatus == PaymentStatus.paid;
    return Semantics(
      selected: selected,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: OperationsTokens.panel.copyWith(
          color: selected
              ? OperationsTokens.selected
              : OperationsTokens.surface,
          border: Border.all(
            color: selected ? OperationsTokens.accent : OperationsTokens.border,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(OperationsTokens.radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    booking.roomName.isEmpty
                        ? AppStrings.roomLabel
                        : booking.roomName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: OperationsTokens.value,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    booking.userName ?? AppStrings.anonymous,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OperationsTokens.label,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _tag(paid ? AppStrings.paid : AppStrings.unpaid),
                      if (booking.isOpenEnded) _tag('cashier.open'.tr()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RepaintBoundary(child: SessionLiveClock(booking: booking)),
                  if (booking.status == BookingStatus.pendingVerification) ...[
                    const SizedBox(height: 8),
                    AppButton(
                      text: AppStrings.pendingVerification,
                      variant: AppButtonVariant.outlined,
                      foregroundColor: OperationsTokens.accent,
                      height: 48,
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            ManualPaymentVerificationDialog(booking: booking),
                      ),
                    ),
                  ] else if (booking.canStartSession) ...[
                    const SizedBox(height: 8),
                    StartSessionButton(
                      bookingId: booking.id,
                      bookingDate: booking.date,
                      startTime: booking.startTime,
                      height: 48,
                    ),
                  ] else if (booking.status == BookingStatus.pending) ...[
                    const SizedBox(height: 8),
                    AppButton(
                      text: AppStrings.confirmBooking,
                      height: 48,
                      onPressed: () => context
                          .read<BookingCubit>()
                          .approveBooking(booking.id),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      text: AppStrings.reject,
                      height: 48,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => context
                          .read<BookingCubit>()
                          .rejectBooking(booking.id),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: OperationsTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: OperationsTokens.border),
    ),
    child: Text(text, style: OperationsTokens.label.copyWith(fontSize: 12)),
  );
}
