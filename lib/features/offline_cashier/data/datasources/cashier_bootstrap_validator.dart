import 'cashier_authority_validator.dart';

/// Validates the complete, scoped snapshot supplied by the bootstrap RPC.
class CashierBootstrapValidator {
  static const invalid = FormatException('offline_cashier.invalid_bootstrap');
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  static void validate(Map response, String actorId, String loungeId) {
    final authority = response['authority'];
    final shift = response['shift'];
    final coverage = response['coverage'];
    if (response['protocol_version'] != 2 ||
        response['complete'] != true ||
        authority is! Map ||
        shift is! Map ||
        coverage is! Map ||
        shift['actor_id'] != actorId ||
        shift['lounge_id'] != loungeId ||
        !_id(shift['id']) ||
        shift['status'] != 'open') {
      throw invalid;
    }
    _amount(shift['collected_cash_minor']);
    final from = _amount(coverage['from_ms']);
    final until = _amount(coverage['until_ms']);
    if (from > _amount(authority['server_time_ms']) ||
        until <= from ||
        until > _amount(authority['expires_ms'])) {
      throw invalid;
    }
    final rooms = _resources(response['rooms'], loungeId);
    for (final room in rooms.values) {
      if (room['is_active'] is! bool ||
          room['is_available'] is! bool ||
          ![
            'available',
            'occupied',
            'maintenance',
            'inactive',
            'deleted',
          ].contains(room['status']) ||
          room['offline_supported'] is! bool) {
        throw invalid;
      }
      _amount(room['single_hour_minor']);
      _amount(room['multi_hour_minor']);
      final blocked = room['blocked_intervals'];
      if (blocked is! List) throw invalid;
      for (final interval in blocked) {
        if (interval is! Map ||
            _amount(interval['end_ms']) <= _amount(interval['start_ms'])) {
          throw invalid;
        }
      }
    }
    final products = _resources(response['products'], loungeId);
    for (final product in products.values) {
      if (product['is_active'] is! bool ||
          product['is_available'] is! bool ||
          product['track_stock'] is! bool) {
        throw invalid;
      }
      _amount(product['unit_price_minor']);
      if (product['track_stock'] == true) {
        _amount(product['stock_quantity']);
      }
    }
    final bookings = _resources(response['bookings'], loungeId);
    for (final booking in bookings.values) {
      _booking(booking, rooms, authority);
    }
  }

  static Map<String, Map> _resources(Object? value, String loungeId) {
    if (value is! Map) throw invalid;
    final resources = <String, Map>{};
    for (final entry in value.entries) {
      final row = entry.value;
      if (!_id(entry.key) ||
          row is! Map ||
          row['id'] != entry.key ||
          row['lounge_id'] != loungeId) {
        throw invalid;
      }
      resources[entry.key as String] = row;
    }
    return resources;
  }

  static void _booking(Map booking, Map rooms, Map authority) {
    if (!rooms.containsKey(booking['room_id']) ||
        booking['timezone'] != authority['timezone'] ||
        ![
          'pending',
          'confirmed',
          'upcoming',
          'in_progress',
          'completed',
          'cancelled',
          'rejected',
          'expired',
        ].contains(booking['status']) ||
        booking['offline_supported'] is! bool ||
        booking['items'] is! List ||
        booking['sync_status'] != 'synced') {
      throw invalid;
    }
    final start = _amount(booking['start_ms']);
    final end = _amount(booking['end_ms']);
    final capacityEnd = _amount(booking['capacity_end_ms']);
    final total = _amount(booking['total_minor']);
    final paid = _amount(booking['paid_minor']);
    if (end <= start ||
        capacityEnd < start ||
        capacityEnd > end ||
        paid > total ||
        (booking['status'] == 'in_progress' &&
            (_amount(booking['started_ms']) < start ||
                _amount(booking['started_ms']) >= end))) {
      throw invalid;
    }
    final expected = paid == total
        ? 'paid'
        : paid > 0
        ? 'partial'
        : 'unpaid';
    if (booking['payment_status'] != expected) throw invalid;
    if (booking['shift_id'] != null && !_id(booking['shift_id'])) throw invalid;
  }

  static bool _id(Object? value) => value is String && _uuid.hasMatch(value);
  static int _amount(Object? value) {
    try {
      return CashierAuthorityValidator.integer(value);
    } on FormatException {
      throw invalid;
    }
  }
}
