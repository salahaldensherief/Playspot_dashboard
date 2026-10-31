import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/analytics/domain/entities/lounge_stats_entity.dart';
import 'package:play_spot_dashboard/features/analytics/presentation/lounge_kpi_snapshot.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';

void main() {
  final now = DateTime(2026, 10, 20, 12, 50);

  Booking booking(
    String id, {
    BookingStatus status = BookingStatus.inProgress,
    String? receiptUrl,
    DateTime? cancelledAt,
  }) => Booking(
    id: id,
    userId: 'user-1',
    loungeId: 'lounge-1',
    roomId: 'room-1',
    date: now,
    startTime: '12:00',
    endTime: '13:00',
    status: status,
    receiptUrl: receiptUrl,
    cancelledAt: cancelledAt,
    totalPrice: 100,
  );

  LoungeKpiSnapshot snapshot({
    LoungeStatsEntity? stats,
    List<Booking> bookings = const [],
    List<Booking> liveSessions = const [],
    bool hasLiveSessionsSnapshot = false,
    List<ClientRequestEntity> requests = const [],
  }) => LoungeKpiSnapshot.fromData(
    stats: stats,
    bookings: bookings,
    liveSessions: liveSessions,
    hasLiveSessionsSnapshot: hasLiveSessionsSnapshot,
    requests: requests,
    fallbackOccupancyRate: 0.25,
    now: now,
  );

  test('an empty live snapshot is authoritative after the stream responds', () {
    final cachedBooking = booking('cached');
    expect(snapshot(bookings: [cachedBooking]).activeSessionsCount, 1);
    expect(
      snapshot(
        bookings: [cachedBooking],
        hasLiveSessionsSnapshot: true,
      ).activeSessionsCount,
      0,
    );
  });

  test('counts attention metrics from the same booking rules', () {
    final request = ClientRequestEntity(
      id: 'request-1',
      loungeId: 'lounge-1',
      titleAr: '',
      titleEn: '',
      bodyAr: '',
      bodyEn: '',
      type: ClientRequestType.callStaff,
      createdAt: now,
    );
    final metrics = snapshot(
      bookings: [
        booking('running'),
        booking('receipt', receiptUrl: 'payment-proofs/file'),
        booking('cancelled', status: BookingStatus.cancelled, cancelledAt: now),
      ],
      requests: [
        request,
        request.copyWith(id: 'attended', isAttended: true),
      ],
    );

    expect(metrics.endingSoonCount, 2);
    expect(metrics.pendingProofsCount, 1);
    expect(metrics.cancellationsCount, 1);
    expect(metrics.unattendedRequestsCount, 1);
  });

  test('server lounge stats take precedence over fallback occupancy', () {
    final metrics = snapshot(
      stats: const LoungeStatsEntity(
        success: true,
        loungeId: 'lounge-1',
        todayRevenue: 250,
        monthlyRevenue: 1000,
        totalRooms: 8,
        occupiedRooms: 3,
        occupancyRate: 0.375,
        activeBookings: 2,
        openShifts: 1,
        lowStockItems: 0,
      ),
    );
    expect(metrics.todayRevenue, 250);
    expect(metrics.occupancyRate, 0.375);
    expect(metrics.occupiedRooms, 3);
    expect(metrics.totalRooms, 8);
  });
}
