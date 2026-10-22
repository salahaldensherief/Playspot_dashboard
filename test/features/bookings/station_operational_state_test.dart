import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/station_operational_state.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

void main() {
  final now = DateTime(2026, 10, 22, 20);
  RoomEntity room(
    String id, {
    RoomStatusEnum status = RoomStatusEnum.available,
  }) => RoomEntity(
    id: id,
    loungeId: 'lounge-a',
    nameAr: id,
    nameEn: id,
    isAvailable: true,
    images: const [],
    featuresAr: const [],
    featuresEn: const [],
    status: status,
  );
  Booking booking(
    String id,
    String roomId,
    BookingStatus status, {
    PaymentStatus payment = PaymentStatus.paid,
    bool open = false,
    String start = '20:00',
  }) => Booking(
    id: id,
    userId: id,
    loungeId: 'lounge-a',
    roomId: roomId,
    roomName: roomId,
    date: now,
    startTime: start,
    endTime: '21:00',
    status: status,
    paymentStatus: payment,
    totalPrice: 100,
    isOpenTime: open,
  );

  test('keeps occupancy, requests, payment and next booking separate', () {
    final states = StationOperationalState.build(
      rooms: [room('pc-1'), room('ps5-1'), room('pc-2')],
      bookings: [
        booking(
          'active',
          'pc-1',
          BookingStatus.inProgress,
          payment: PaymentStatus.partial,
          open: true,
        ),
        booking('next', 'pc-1', BookingStatus.upcoming, start: '21:30'),
        booking('pending', 'ps5-1', BookingStatus.pending),
        booking(
          'other-lounge',
          'pc-2',
          BookingStatus.inProgress,
        ).copyWith(loungeId: 'lounge-b'),
      ],
      requests: [
        ClientRequestEntity(
          id: 'help',
          loungeId: 'lounge-a',
          roomId: 'pc-1',
          titleAr: 'مساعدة',
          titleEn: 'Help',
          bodyAr: '',
          bodyEn: '',
          type: ClientRequestType.callStaff,
          createdAt: now,
        ),
      ],
      roomDataFresh: true,
      now: now,
    );

    expect(states[0].active?.id, 'active');
    expect(states[0].next?.id, 'next');
    expect(states[0].attentionRequests, 1);
    expect(states[0].needsAttention, isTrue);
    expect(states[0].canClaimAvailable, isFalse);
    expect(states[1].pending?.id, 'pending');
    expect(states[1].canClaimAvailable, isFalse);
    expect(states[2].active, isNull);
    expect(states[2].canClaimAvailable, isTrue);
  });

  test('stale or occupied room state cannot claim availability', () {
    final stale = StationOperationalState.build(
      rooms: [room('pc-1')],
      bookings: const [],
      requests: const [],
      roomDataFresh: false,
    );
    final occupied = StationOperationalState.build(
      rooms: [room('pc-2', status: RoomStatusEnum.occupied)],
      bookings: const [],
      requests: const [],
      roomDataFresh: true,
    );
    expect(stale.single.canClaimAvailable, isFalse);
    expect(occupied.single.canClaimAvailable, isFalse);
  });

  test('multiple active bookings on one station demand manual review', () {
    final states = StationOperationalState.build(
      rooms: [room('pc-1')],
      bookings: [
        booking('first', 'pc-1', BookingStatus.inProgress),
        booking('second', 'pc-1', BookingStatus.inProgress),
      ],
      requests: const [],
      roomDataFresh: true,
      now: now,
    );
    expect(states.single.activeBookingCount, 2);
    expect(states.single.needsAttention, isTrue);
    expect(states.single.canClaimAvailable, isFalse);
  });
}
