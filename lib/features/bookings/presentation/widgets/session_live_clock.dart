import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/booking.dart';
import 'session_fact.dart';
import 'session_ticker.dart';

class SessionLiveClock extends StatelessWidget {
  final Booking booking;
  const SessionLiveClock({super.key, required this.booking});
  @override
  Widget build(BuildContext context) {
    final now = SessionTickerScope.nowOf(context);
    final start = booking.startDateTime;
    final upcoming = start != null && now.isBefore(start);
    final duration = upcoming
        ? start.difference(now)
        : booking.remainingDuration(now);
    final seconds = duration.inSeconds.abs();
    final value =
        '${seconds ~/ 3600}:${((seconds ~/ 60) % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return SessionFact(
      label:
          (upcoming
                  ? 'starts_in'
                  : booking.isOpenEnded
                  ? 'cashier.elapsed'
                  : duration.isNegative
                  ? 'cashier.overtime'
                  : 'cashier.remaining')
              .tr(),
      value: value,
    );
  }
}
