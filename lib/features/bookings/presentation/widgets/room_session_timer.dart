import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import '../../domain/entities/booking.dart';
import 'session_time_builder.dart';

/// A native, accessible timer. The server schedule remains authoritative.
class RoomSessionTimer extends StatelessWidget {
  final Booking booking;
  const RoomSessionTimer({super.key, required this.booking});

  @override
  Widget build(BuildContext context) => SessionTimeBuilder(
    builder: (context, now) {
      final open = booking.isOpenEnded;
      final expired = booking.isSessionExpired(now);
      final duration = booking.remainingDuration(now);
      final seconds = duration.inSeconds.abs();
      final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
      final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      final value =
          '${!open && duration.isNegative ? '-' : ''}'
          '${seconds >= 3600 ? '$hours:' : ''}$minutes:$secs';
      final label = open
          ? '${AppStrings.openTime} · ${AppStrings.elapsedTime}'
          : expired
          ? AppStrings.timeExpired
          : AppStrings.remainingTime;
      return Semantics(
        label: '$label $value',
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: expired && !open ? AppColors.warning : Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: Color(0xffc8d8ee),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
