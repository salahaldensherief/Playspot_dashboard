import '../../../rooms/domain/entities/room_entity.dart';
import '../../../requests/domain/entities/client_request_entity.dart';
import 'booking.dart';

/// A read-only projection for the cashier board. It never grants inventory or
/// physical-device authority; the server still decides every action.
class StationOperationalState {
  final RoomEntity room;
  final Booking? active;
  final Booking? pending;
  final Booking? next;
  final int activeBookingCount;
  final int attentionRequests;
  final bool roomDataFresh;

  const StationOperationalState({
    required this.room,
    required this.active,
    required this.pending,
    required this.next,
    required this.activeBookingCount,
    required this.attentionRequests,
    required this.roomDataFresh,
  });

  bool get needsAttention =>
      activeBookingCount > 1 ||
      attentionRequests > 0 ||
      pending != null ||
      (active != null &&
          !active!.isOpenEnded &&
          active!.paymentStatus != PaymentStatus.paid) ||
      (active != null && next != null && active!.isOpenEnded);

  bool get canClaimAvailable =>
      roomDataFresh &&
      room.isAvailable &&
      room.status == RoomStatusEnum.available &&
      active == null &&
      pending == null;

  static List<StationOperationalState> build({
    required List<RoomEntity> rooms,
    required List<Booking> bookings,
    required List<ClientRequestEntity> requests,
    required bool roomDataFresh,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    return [
      for (final room in rooms)
        _forRoom(room, bookings, requests, roomDataFresh, clock),
    ];
  }

  static StationOperationalState _forRoom(
    RoomEntity room,
    List<Booking> bookings,
    List<ClientRequestEntity> requests,
    bool fresh,
    DateTime now,
  ) {
    final scoped = bookings.where(
      (b) => b.loungeId == room.loungeId && b.roomId == room.id,
    );
    final activeBookings = scoped
        .where((b) => b.status == BookingStatus.inProgress)
        .toList();
    final active = activeBookings.firstOrNull;
    final pending = scoped
        .where((b) => b.status == BookingStatus.pending)
        .firstOrNull;
    final upcoming =
        scoped
            .where(
              (b) =>
                  b.status == BookingStatus.upcoming &&
                  b.startDateTime != null &&
                  b.startDateTime!.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.startDateTime!.compareTo(b.startDateTime!));
    return StationOperationalState(
      room: room,
      active: active,
      pending: pending,
      next: upcoming.firstOrNull,
      activeBookingCount: activeBookings.length,
      attentionRequests: requests
          .where(
            (r) =>
                r.loungeId == room.loungeId &&
                r.roomId == room.id &&
                !r.isAttended,
          )
          .length,
      roomDataFresh: fresh,
    );
  }
}
