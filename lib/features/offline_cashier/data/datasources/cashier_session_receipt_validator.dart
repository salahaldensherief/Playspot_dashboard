class CashierSessionReceiptValidator {
  static const _invalid = FormatException(
    'offline_cashier.invalid_sync_response',
  );
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static void validate(Map operation, Map receipt) {
    final context = operation['quoted_session'];
    final expected = switch (operation['kind']) {
      'reserve' => 'upcoming',
      'start' => 'in_progress',
      'close' => 'completed',
      _ => throw _invalid,
    };
    if (context is! Map ||
        receipt['status'] != expected ||
        receipt['shift_id'] != operation['shift_id'] ||
        receipt['room_id'] is! String ||
        !_uuid.hasMatch(receipt['room_id']) ||
        receipt['timezone'] is! String ||
        (receipt['timezone'] as String).isEmpty ||
        _integer(receipt['total_minor']) <= 0 ||
        receipt['total_minor'] != _integer(operation['quoted_total_minor']) ||
        receipt['paid_minor'] != _integer(context['paid_minor']) ||
        _integer(receipt['paid_minor']) + _integer(receipt['due_minor']) !=
            receipt['total_minor']) {
      throw _invalid;
    }
    for (final key in ['room_id', 'timezone', 'start_ms', 'end_ms']) {
      if (receipt[key] != context[key]) throw _invalid;
    }
    _validateInterval(operation, receipt, context);
    _validateTransition(operation, receipt, context);
  }

  static void _validateInterval(Map operation, Map receipt, Map context) {
    final start = _integer(receipt['start_ms']);
    final end = _integer(receipt['end_ms']);
    final capacity = _integer(receipt['capacity_end_ms']);
    if (start % 60000 != 0 ||
        end % 60000 != 0 ||
        end <= start ||
        end - start > 86400000 ||
        end > 253402300799000 ||
        capacity < start ||
        capacity > end) {
      throw _invalid;
    }
    if (operation['kind'] == 'reserve') {
      final payload = operation['payload'];
      if (payload is! Map ||
          _instant(operation['occurred_at']) ~/ 60000 * 60000 > start) {
        throw _invalid;
      }
      for (final key in ['room_id', 'timezone', 'start_ms', 'end_ms']) {
        if (context[key] != payload[key]) throw _invalid;
      }
    }
  }

  static void _validateTransition(Map operation, Map receipt, Map context) {
    final occurred = _instant(operation['occurred_at']);
    final start = _integer(receipt['start_ms']);
    final end = _integer(receipt['end_ms']);
    if (operation['kind'] == 'reserve') {
      if (receipt['started_at'] != null ||
          receipt['closed_at'] != null ||
          context['started_ms'] != null ||
          receipt['capacity_end_ms'] != end ||
          receipt['paid_minor'] != 0) {
        throw _invalid;
      }
      return;
    }
    final started = _instant(receipt['started_at']);
    if (started != _integer(context['started_ms']) ||
        started < start ||
        started >= end) {
      throw _invalid;
    }
    if (operation['kind'] == 'start') {
      if (started != occurred ||
          receipt['closed_at'] != null ||
          receipt['capacity_end_ms'] != end) {
        throw _invalid;
      }
    } else if (_instant(receipt['closed_at']) != occurred ||
        occurred < started ||
        receipt['capacity_end_ms'] != occurred.clamp(start, end)) {
      throw _invalid;
    }
  }

  static int _integer(Object? value) {
    if (value is! num ||
        !value.isFinite ||
        value < 0 ||
        value > 9007199254740991 ||
        value != value.round()) {
      throw _invalid;
    }
    return value.toInt();
  }

  static int _instant(Object? value) {
    if (value is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}T.*(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
      throw _invalid;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw _invalid;
    return parsed.millisecondsSinceEpoch;
  }

  static Map<String, dynamic> projection(Map receipt) => {
    for (final key in [
      'room_id',
      'shift_id',
      'status',
      'timezone',
      'start_ms',
      'end_ms',
      'capacity_end_ms',
      'started_at',
      'closed_at',
    ])
      key: receipt[key],
  };
}
