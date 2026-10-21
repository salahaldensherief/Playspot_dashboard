import 'package:play_spot_dashboard/features/analytics/domain/entities/lounge_stats_entity.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';

class LoungeKpiSnapshot {
  const LoungeKpiSnapshot._({
    required this.todayRevenue,
    required this.occupancyRate,
    required this.occupiedRooms,
    required this.totalRooms,
    required this.activeSessionsCount,
    required this.endingSoonCount,
    required this.pendingProofsCount,
    required this.unattendedRequestsCount,
    required this.cancellationsCount,
  });

  final double todayRevenue;
  final double occupancyRate;
  final int occupiedRooms;
  final int totalRooms;
  final int activeSessionsCount;
  final int endingSoonCount;
  final int pendingProofsCount;
  final int unattendedRequestsCount;
  final int cancellationsCount;

  factory LoungeKpiSnapshot.fromData({
    required LoungeStatsEntity? stats,
    required List<Booking> bookings,
    required List<Booking> liveSessions,
    required bool hasLiveSessionsSnapshot,
    required List<ClientRequestEntity> requests,
    required double fallbackOccupancyRate,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final activeSource = hasLiveSessionsSnapshot ? liveSessions : bookings;

    return LoungeKpiSnapshot._(
      todayRevenue: stats?.todayRevenue ?? 0,
      occupancyRate: stats?.occupancyRate ?? fallbackOccupancyRate,
      occupiedRooms: stats?.occupiedRooms ?? 0,
      totalRooms: stats?.totalRooms ?? 0,
      activeSessionsCount: activeSource
          .where((booking) => booking.status == BookingStatus.inProgress)
          .length,
      endingSoonCount: bookings.where((booking) {
        if (booking.status != BookingStatus.inProgress || booking.isOpenEnded) {
          return false;
        }
        final remaining = booking.remainingDuration(currentTime);
        return remaining > Duration.zero &&
            remaining <= const Duration(minutes: 15);
      }).length,
      pendingProofsCount: bookings
          .where((booking) => booking.needsPaymentProofReview)
          .length,
      unattendedRequestsCount: requests
          .where((request) => !request.isAttended)
          .length,
      cancellationsCount: bookings.where((booking) {
        final cancelledAt = booking.cancelledAt?.toLocal();
        return cancelledAt != null &&
            cancelledAt.year == currentTime.year &&
            cancelledAt.month == currentTime.month &&
            cancelledAt.day == currentTime.day &&
            (booking.status == BookingStatus.cancelled ||
                booking.status == BookingStatus.rejected);
      }).length,
    );
  }
}
