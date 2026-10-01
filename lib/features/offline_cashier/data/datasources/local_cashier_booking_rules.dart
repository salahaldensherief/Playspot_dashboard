import '../../domain/entities/local_cashier_command.dart';

class LocalCashierBookingRules {
  static void reserve(Map<String, dynamic> state, LocalCashierCommand command) {
    final bookings = state['bookings'] as Map;
    final payload = command.payload;
    final roomId = payload['room_id'];
    final room = (state['rooms'] as Map? ?? const {})[roomId] as Map?;
    final start = payload['start_ms'];
    final end = payload['end_ms'];
    if (bookings.containsKey(command.bookingId) ||
        room == null ||
        room['is_active'] != true ||
        room['status'] == 'maintenance' ||
        start is! int ||
        end is! int ||
        end <= start ||
        end - start > const Duration(days: 1).inMilliseconds) {
      throw StateError('offline_cashier.invalid_booking');
    }
    final rate = payload['play_mode'] == 'multi'
        ? room['multi_hour_minor']
        : room['single_hour_minor'];
    final quantum = room['billing_quantum_minutes'];
    if (rate is! int ||
        rate < 0 ||
        quantum is! int ||
        quantum < 1 ||
        quantum > 60 ||
        !['single', 'multi'].contains(payload['play_mode'])) {
      throw StateError('offline_cashier.invalid_pricing_snapshot');
    }
    final quantumMs = quantum * 60000;
    final chargedMs = ((end - start + quantumMs - 1) ~/ quantumMs) * quantumMs;
    final total = (rate * chargedMs + 3599999) ~/ 3600000;
    if (payload['total_minor'] != null && payload['total_minor'] != total) {
      throw StateError('offline_cashier.price_mismatch');
    }
    for (final value in bookings.values) {
      final booking = value as Map;
      if (booking['room_id'] == roomId &&
          !['cancelled', 'completed', 'rejected'].contains(booking['status']) &&
          (booking['start_ms'] as int) < end &&
          (booking['end_ms'] as int) > start) {
        throw StateError('offline_cashier.room_conflict');
      }
    }
    bookings[command.bookingId] = {
      ...payload,
      'total_minor': total,
      'id': command.bookingId,
      'lounge_id': command.loungeId,
      'status': 'upcoming',
      'paid_minor': 0,
      'items': <dynamic>[],
      'shift_id': (state['shift'] as Map)['id'],
      'sync_status': 'pending',
    };
  }

  static Map booking(Map<String, dynamic> state, LocalCashierCommand command) {
    final booking = (state['bookings'] as Map)[command.bookingId] as Map?;
    if (booking == null || booking['lounge_id'] != command.loungeId) {
      throw StateError('offline_cashier.booking_not_found');
    }
    return booking;
  }

  static void start(Map<String, dynamic> state, LocalCashierCommand command) {
    final current = booking(state, command);
    if (current['status'] != 'upcoming') {
      throw StateError('offline_cashier.invalid_transition');
    }
    current['status'] = 'in_progress';
    current['checked_in_at'] = command.occurredAt.toUtc().toIso8601String();
  }

  static void close(Map<String, dynamic> state, LocalCashierCommand command) {
    final current = booking(state, command);
    if (current['status'] != 'in_progress') {
      throw StateError('offline_cashier.invalid_transition');
    }
    current['status'] = 'completed';
    current['closed_at'] = command.occurredAt.toUtc().toIso8601String();
    // Closing never invents a payment: the outstanding amount remains visible.
  }
}
