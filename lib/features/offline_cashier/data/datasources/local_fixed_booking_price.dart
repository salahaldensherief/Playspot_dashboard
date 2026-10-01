import '../../domain/entities/local_cashier_command.dart';

class LocalFixedBookingPrice {
  static int quote(Map room, LocalCashierCommand command) {
    final minutes = _minutes(command);
    final rate = _rate(room, command.payload);
    _validateCustomer(command.payload);
    final exact =
        (BigInt.from(rate) * BigInt.from(minutes) + BigInt.from(30)) ~/
        BigInt.from(60);
    if (exact <= BigInt.zero || exact > BigInt.from(9007199254740991)) {
      throw StateError('offline_cashier.price_mismatch');
    }
    final total = exact.toInt();
    final quoted = command.payload['total_minor'];
    if (quoted != null && quoted != total) {
      throw StateError('offline_cashier.price_mismatch');
    }
    return total;
  }

  static int _minutes(LocalCashierCommand command) {
    final start = command.payload['start_ms'];
    final end = command.payload['end_ms'];
    if (start is! int ||
        end is! int ||
        start < 0 ||
        end > 253402300799000 ||
        start % 60000 != 0 ||
        end % 60000 != 0 ||
        end <= start ||
        end - start > 86400000 ||
        start < (command.occurredAt.millisecondsSinceEpoch ~/ 60000) * 60000) {
      throw StateError('offline_cashier.invalid_pricing_snapshot');
    }
    return (end - start) ~/ 60000;
  }

  static int _rate(Map room, Map payload) {
    final rate = payload['play_mode'] == 'multi'
        ? room['multi_hour_minor']
        : room['single_hour_minor'];
    if (rate is! int ||
        rate <= 0 ||
        rate > 9007199254740991 ||
        !['single', 'multi'].contains(payload['play_mode']) ||
        payload['timezone'] is! String ||
        (payload['timezone'] as String).isEmpty) {
      throw StateError('offline_cashier.invalid_pricing_snapshot');
    }
    return rate;
  }

  static void _validateCustomer(Map payload) {
    final name = payload['customer_name'];
    final phone = payload['customer_phone'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > 120 ||
        (phone != null && (phone is! String || phone.length > 32))) {
      throw StateError('offline_cashier.invalid_booking');
    }
  }
}
