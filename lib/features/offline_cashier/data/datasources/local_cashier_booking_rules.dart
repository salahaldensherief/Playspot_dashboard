import '../../domain/entities/local_cashier_command.dart';
import 'local_fixed_booking_price.dart';

class LocalCashierBookingRules {
  static void reserve(Map<String, dynamic> state, LocalCashierCommand command) {
    final bookings = state['bookings'] as Map;
    final payload = command.payload;
    final roomId = payload['room_id'];
    final room = _eligibleRoom(state, roomId);
    final bootstrap = state['bootstrap'];
    if (bootstrap is Map) {
      final coverage = bootstrap['coverage'] as Map;
      if (room['offline_supported'] != true ||
          payload['timezone'] != (state['authority'] as Map)['timezone'] ||
          payload['start_ms'] is! int ||
          payload['end_ms'] is! int ||
          payload['start_ms'] < coverage['from_ms'] ||
          payload['end_ms'] > coverage['until_ms']) {
        throw StateError('offline_cashier.outside_bootstrap');
      }
      for (final interval in room['blocked_intervals'] as List) {
        if (interval['start_ms'] < payload['end_ms'] &&
            interval['end_ms'] > payload['start_ms']) {
          throw StateError('offline_cashier.room_conflict');
        }
      }
    }
    if (bookings.containsKey(command.bookingId)) {
      throw StateError('offline_cashier.invalid_booking');
    }
    final total = LocalFixedBookingPrice.quote(room, command);
    _assertCapacity(bookings, payload);
    bookings[command.bookingId] = {
      ...payload,
      'total_minor': total,
      'id': command.bookingId,
      'lounge_id': command.loungeId,
      'status': 'upcoming',
      'paid_minor': 0,
      'payment_status': total == 0 ? 'paid' : 'unpaid',
      'items': <dynamic>[],
      'shift_id': (state['shift'] as Map)['id'],
      'sync_status': 'pending',
      if (bootstrap is Map) 'offline_supported': true,
    };
  }

  static Map _eligibleRoom(Map state, Object? roomId) {
    final room = (state['rooms'] as Map? ?? const {})[roomId] as Map?;
    if (room == null ||
        room['is_active'] != true ||
        !['available', 'occupied'].contains(room['status']) ||
        (room['is_available'] != true && room['status'] != 'occupied')) {
      throw StateError('offline_cashier.invalid_booking');
    }
    return room;
  }

  static void _assertCapacity(Map bookings, Map payload) {
    final start = payload['start_ms'] as int;
    final end = payload['end_ms'] as int;
    for (final value in bookings.values) {
      final booking = value as Map;
      if (booking['room_id'] == payload['room_id'] &&
          !['cancelled', 'rejected'].contains(booking['status']) &&
          (booking['start_ms'] as int) < end &&
          ((booking['capacity_end_ms'] as int?) ?? (booking['end_ms'] as int)) >
              start) {
        throw StateError('offline_cashier.room_conflict');
      }
    }
  }

  static Map booking(Map<String, dynamic> state, LocalCashierCommand command) {
    final booking = (state['bookings'] as Map)[command.bookingId] as Map?;
    if (booking == null || booking['lounge_id'] != command.loungeId) {
      throw StateError('offline_cashier.booking_not_found');
    }
    if (state['bootstrap'] is Map &&
        (booking['offline_supported'] != true ||
            booking['shift_id'] != command.shiftId)) {
      throw StateError('offline_cashier.invalid_transition');
    }
    return booking;
  }

  static void start(Map<String, dynamic> state, LocalCashierCommand command) {
    final current = booking(state, command);
    final occurred = command.occurredAt.millisecondsSinceEpoch;
    if (current['status'] != 'upcoming' ||
        occurred < (current['start_ms'] as int) ||
        occurred >= (current['end_ms'] as int)) {
      throw StateError('offline_cashier.invalid_transition');
    }
    _eligibleRoom(state, current['room_id']);
    // A session running past its scheduled end still physically occupies the room.
    for (final other in (state['bookings'] as Map).values) {
      if (other['id'] != current['id'] &&
          other['room_id'] == current['room_id'] &&
          other['status'] == 'in_progress') {
        throw StateError('offline_cashier.room_conflict');
      }
    }
    current['status'] = 'in_progress';
    current['checked_in_at'] = command.occurredAt.toUtc().toIso8601String();
    current['started_ms'] = occurred;
  }

  static void close(Map<String, dynamic> state, LocalCashierCommand command) {
    final current = booking(state, command);
    final occurred = command.occurredAt.millisecondsSinceEpoch;
    final started = current['started_ms'];
    if (current['status'] != 'in_progress' ||
        started is! int ||
        occurred < started) {
      throw StateError('offline_cashier.invalid_transition');
    }
    current['status'] = 'completed';
    current['closed_at'] = command.occurredAt.toUtc().toIso8601String();
    current['capacity_end_ms'] = occurred.clamp(
      current['start_ms'] as int,
      current['end_ms'] as int,
    );
    // Closing never invents a payment: the outstanding amount remains visible.
  }
}
