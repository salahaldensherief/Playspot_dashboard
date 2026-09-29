import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_empty_state_widget.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_section_header.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/booking_card.dart';
import 'package:play_spot_dashboard/features/bookings/presentation/widgets/live_session_card.dart';

class LiveSessionsOperationsBoard extends StatelessWidget {
  final List<Booking> bookings;
  final ValueChanged<Booking> onShowDetails;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  const LiveSessionsOperationsBoard({
    super.key,
    required this.bookings,
    required this.onShowDetails,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final groups = LiveSessionsOperationsGroups.fromBookings(bookings);

    final sections = <_OperationsSectionData>[
      if (groups.needsAttention.isNotEmpty)
        _OperationsSectionData(
          title: AppStrings.sessionsNeedAttention,
          subtitle: AppStrings.sessionsNeedAttentionSubtitle,
          icon: Icons.notification_important_outlined,
          color: AppColors.danger,
          bookings: groups.needsAttention,
        ),
      if (groups.openTime.isNotEmpty)
        _OperationsSectionData(
          title: AppStrings.openTimeSessions,
          subtitle: AppStrings.openTimeSessionsSubtitle,
          icon: Icons.all_inclusive_rounded,
          color: AppColors.neonCyan,
          bookings: groups.openTime,
        ),
      if (groups.running.isNotEmpty)
        _OperationsSectionData(
          title: AppStrings.runningSessions,
          subtitle: AppStrings.runningSessionsSubtitle,
          icon: Icons.sports_esports_outlined,
          color: AppColors.neonGreen,
          bookings: groups.running,
        ),
      if (groups.upcoming.isNotEmpty)
        _OperationsSectionData(
          title: AppStrings.upcomingSessions,
          subtitle: AppStrings.upcomingSessionsSubtitle,
          icon: Icons.event_available_outlined,
          color: AppColors.neonBlue,
          bookings: groups.upcoming,
        ),
    ];

    if (sections.isEmpty) {
      return _EmptyOperationsState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          _OperationsSection(
            data: sections[index],
            onShowDetails: onShowDetails,
            onApprove: onApprove,
            onReject: onReject,
          ),
          if (index < sections.length - 1) SizedBox(height: 22.h),
        ],
      ],
    );
  }
}

class LiveSessionsOperationsGroups {
  final List<Booking> needsAttention;
  final List<Booking> openTime;
  final List<Booking> running;
  final List<Booking> upcoming;

  const LiveSessionsOperationsGroups({
    required this.needsAttention,
    required this.openTime,
    required this.running,
    required this.upcoming,
  });

  factory LiveSessionsOperationsGroups.fromBookings(
    List<Booking> bookings, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final inProgress = bookings
        .where((booking) => booking.status == BookingStatus.inProgress)
        .toList();
    final needsAttention =
        inProgress.where((booking) => _needsAttention(booking, clock)).toList()
          ..sort(
            (a, b) =>
                _urgencyScore(b, clock).compareTo(_urgencyScore(a, clock)),
          );
    final attentionIds = needsAttention.map((booking) => booking.id).toSet();
    final openTime = inProgress
        .where(
          (booking) =>
              booking.isOpenEnded && !attentionIds.contains(booking.id),
        )
        .toList();
    final running =
        inProgress
            .where(
              (booking) =>
                  !booking.isOpenEnded && !attentionIds.contains(booking.id),
            )
            .toList()
          ..sort(
            (a, b) => a
                .remainingDuration(clock)
                .compareTo(b.remainingDuration(clock)),
          );
    final upcoming =
        bookings
            .where((booking) => booking.status == BookingStatus.upcoming)
            .toList()
          ..sort(
            (a, b) => (a.startDateTime ?? a.date).compareTo(
              b.startDateTime ?? b.date,
            ),
          );

    return LiveSessionsOperationsGroups(
      needsAttention: needsAttention,
      openTime: openTime,
      running: running,
      upcoming: upcoming,
    );
  }

  static bool _needsAttention(Booking booking, DateTime now) {
    if (booking.paymentStatus != PaymentStatus.paid) return true;
    if (booking.isOpenEnded) return false;
    return booking.remainingDuration(now) <= const Duration(minutes: 10);
  }

  static int _urgencyScore(Booking booking, DateTime now) {
    var score = booking.paymentStatus != PaymentStatus.paid ? 1000 : 0;
    final remaining = booking.remainingDuration(now);
    if (remaining.isNegative) {
      score += 500 + remaining.inMinutes.abs();
    } else if (remaining <= const Duration(minutes: 10)) {
      score += 200 - remaining.inMinutes;
    }
    return score;
  }
}

class _OperationsSectionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Booking> bookings;

  const _OperationsSectionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bookings,
  });
}

class _OperationsSection extends StatelessWidget {
  final _OperationsSectionData data;
  final ValueChanged<Booking> onShowDetails;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  const _OperationsSection({
    required this.data,
    required this.onShowDetails,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: data.title,
          subtitle: data.subtitle,
          icon: data.icon,
          iconColor: data.color,
          badgeCount: data.bookings.length,
        ),
        SizedBox(height: 12.h),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1280 ? 3 : (width >= 720 ? 2 : 1);
            final spacing = 14.r;
            final itemWidth = (width - (spacing * (columns - 1))) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: data.bookings
                  .map(
                    (booking) => SizedBox(
                      width: itemWidth,
                      height: 515.h,
                      child: booking.status == BookingStatus.inProgress
                          ? LiveSessionCard(
                              key: ValueKey('operations_live_${booking.id}'),
                              booking: booking,
                              width: double.infinity,
                            )
                          : BookingCard(
                              key: ValueKey('operations_booking_${booking.id}'),
                              booking: booking,
                              width: double.infinity,
                              onApprove: booking.status == BookingStatus.pending
                                  ? () => onApprove(booking.id)
                                  : null,
                              onReject: booking.status == BookingStatus.pending
                                  ? () => onReject(booking.id)
                                  : null,
                              onConfirmPayment: () => onShowDetails(booking),
                            ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyOperationsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: AppEmptyStateWidget(
        icon: Icons.check_circle_outline_rounded,
        title: AppStrings.noSessionsInOperations,
      ),
    );
  }
}
