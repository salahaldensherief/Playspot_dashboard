import 'cashier_command_codec.dart';
import '../../domain/entities/cashier_connection_mode.dart';

class CashierAuthorityValidator {
  static const invalid = FormatException('offline_cashier.invalid_authority');
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static void validate(
    Map authority, {
    required String actorId,
    required String loungeId,
    required String deviceId,
    required CashierConnectionMode mode,
    required DateTime now,
  }) {
    if (authority['protocol_version'] != 2 ||
        authority['actor_id'] != actorId ||
        authority['lounge_id'] != loungeId ||
        authority['device_id'] != deviceId ||
        authority['profile_active'] != true ||
        authority['profile_banned'] != false ||
        authority['lounge_status'] != 'active' ||
        authority['lounge_active'] != true ||
        authority['offline_enabled'] != true ||
        authority['online_requested'] !=
            (mode == CashierConnectionMode.online) ||
        authority['timezone'] is! String ||
        (authority['timezone'] as String).isEmpty) {
      throw invalid;
    }
    for (final key in ['actor_id', 'lounge_id', 'device_id', 'permit_id']) {
      if (authority[key] is! String || !_uuid.hasMatch(authority[key])) {
        throw invalid;
      }
    }
    _validatePermissions(authority);
    _validateTimes(authority, now, mode);
    integer(authority['last_applied_sequence']);
  }

  static void _validatePermissions(Map authority) {
    final permissions = authority['permissions'];
    if (permissions is! Map || permissions['sessions_control'] != true) {
      throw invalid;
    }
    for (final key in [
      'bookings.manage',
      'sessions_control',
      'billing_checkout',
    ]) {
      if (permissions[key] is! bool) throw invalid;
    }
  }

  static void _validateTimes(
    Map authority,
    DateTime now,
    CashierConnectionMode mode,
  ) {
    final issued = integer(authority['issued_ms']);
    final expires = integer(authority['expires_ms']);
    final server = integer(authority['server_time_ms']);
    final heartbeat = authority['heartbeat_expires_at'];
    if (expires <= issued ||
        expires - issued > 86400000 ||
        issued > server ||
        server >= expires ||
        (now.millisecondsSinceEpoch - server).abs() > 300000 ||
        now.millisecondsSinceEpoch >= expires ||
        heartbeat is! String ||
        !RegExp(
          r'^\d{4}-\d{2}-\d{2}T.*(Z|[+-]\d{2}:\d{2})$',
        ).hasMatch(heartbeat)) {
      throw invalid;
    }
    final parsed = DateTime.tryParse(heartbeat);
    if (parsed == null) throw invalid;
    final delta = parsed.millisecondsSinceEpoch - server;
    if (mode == CashierConnectionMode.online
        ? delta <= 0 || delta > 90000
        : delta != 0) {
      throw invalid;
    }
  }

  static int integer(Object? value) {
    if (value is! num ||
        !value.isFinite ||
        value < 0 ||
        value > 9007199254740991 ||
        value != value.round()) {
      throw invalid;
    }
    return value.toInt();
  }

  static Map<String, dynamic> immutableFacts(Map authority) => {
    for (final key in [
      'actor_id',
      'lounge_id',
      'device_id',
      'permit_id',
      'issued_ms',
      'expires_ms',
      'permissions',
    ])
      key: authority[key],
  };

  static bool sameFacts(Map first, Map second) =>
      CashierCommandCodec.canonical(immutableFacts(first)) ==
      CashierCommandCodec.canonical(immutableFacts(second));

  static bool isIssuedEvent(Object? grant, Map operation) {
    if (grant is! Map) return false;
    for (final key in ['actor_id', 'lounge_id', 'device_id', 'permit_id']) {
      if (grant[key] != operation[key]) return false;
    }
    final permission = switch (operation['kind']) {
      'reserve' => 'bookings.manage',
      'collectCash' => 'billing_checkout',
      'start' || 'close' || 'addItems' => 'sessions_control',
      _ => null,
    };
    final permissions = grant['permissions'];
    final time = operation['occurred_at'];
    final issued = grant['issued_ms'];
    final expires = grant['expires_ms'];
    if (permission == null ||
        permissions is! Map ||
        permissions[permission] != true ||
        time is! String ||
        !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(time) ||
        issued is! int ||
        expires is! int ||
        expires <= issued ||
        expires - issued > 86400000) {
      return false;
    }
    final event = DateTime.tryParse(time)?.millisecondsSinceEpoch;
    return event != null && issued <= event && event < expires;
  }
}
