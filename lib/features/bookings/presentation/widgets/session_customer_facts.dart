import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../art_core/app_strings.dart';
import '../../../../art_core/widgets/operations_facts_grid.dart';
import '../../domain/entities/booking.dart';
import 'session_fact.dart';
import 'session_live_clock.dart';

class SessionCustomerFacts extends StatelessWidget {
  final Booking booking;
  const SessionCustomerFacts({super.key, required this.booking});
  @override
  Widget build(BuildContext context) => OperationsFactsGrid(
    children: [
      SessionFact(
        label: 'cashier.customer'.tr(),
        value: booking.userName?.trim().isNotEmpty == true
            ? booking.userName ?? ''
            : AppStrings.anonymous,
      ),
      if (booking.userPhone?.isNotEmpty == true)
        SessionFact(label: AppStrings.phone, value: booking.userPhone ?? ''),
      SessionFact(
        label: 'cashier.playMode'.tr(),
        value: booking.playMode?.tr() ?? 'cashier.unspecified'.tr(),
      ),
      SessionFact(label: 'cashier.start'.tr(), value: booking.startTime),
      SessionLiveClock(booking: booking),
    ],
  );
}
