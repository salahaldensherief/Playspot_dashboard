import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/app_strings.dart';
import '../../domain/entities/booking.dart';
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
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Material(
      color: selected ? AppColors.mutedBackground : AppColors.cardBackground,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(OperationsTokens.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(booking.roomName, style: OperationsTokens.value),
              Text(booking.userName ?? AppStrings.anonymous),
              Text(
                AppStrings.paymentStatusLabel(booking.paymentStatus.name.tr()),
              ),
              Text(
                booking.isOpenEnded ? 'cashier.open'.tr() : booking.startTime,
              ),
              RepaintBoundary(child: SessionLiveClock(booking: booking)),
            ],
          ),
        ),
      ),
    ),
  );
}
