import '../../domain/entities/local_cashier_command.dart';
import 'cashier_authority_validator.dart';

class LocalCashierAuthorityRules {
  static void authorize(
    Map state,
    LocalCashierCommand command, {
    required String actorId,
    required String loungeId,
    required DateTime now,
  }) {
    _validateIds(command);
    if (state['authority_review_required'] == true) {
      throw StateError('offline_cashier.authority_review_required');
    }
    final authority = state['authority'];
    if (authority is! Map ||
        authority['actor_id'] != actorId ||
        authority['lounge_id'] != loungeId ||
        command.actorId != actorId ||
        command.loungeId != loungeId ||
        authority['device_id'] != command.deviceId ||
        authority['permit_id'] != command.permitId ||
        authority['profile_active'] != true ||
        authority['profile_banned'] != false ||
        authority['lounge_status'] != 'active' ||
        authority['lounge_active'] != true) {
      throw StateError('offline_cashier.permission_denied');
    }
    _validateGrant(state, authority, command, now);
    final permissions = authority['permissions'];
    final required = switch (command.kind) {
      LocalCashierCommandKind.reserve => 'bookings.manage',
      LocalCashierCommandKind.collectCash => 'billing_checkout',
      _ => 'sessions_control',
    };
    if (permissions is! Map || permissions[required] != true) {
      throw StateError('offline_cashier.permission_denied');
    }
    _validateShift(state, command);
  }

  static void _validateIds(LocalCashierCommand command) {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    for (final id in [
      command.id,
      command.bookingId,
      command.deviceId,
      command.shiftId,
      command.permitId,
    ]) {
      if (!uuid.hasMatch(id)) {
        throw StateError('offline_cashier.invalid_command');
      }
    }
  }

  static void _validateGrant(
    Map state,
    Map authority,
    LocalCashierCommand command,
    DateTime now,
  ) {
    final issued = authority['issued_ms'];
    final expires = authority['expires_ms'];
    final occurred = command.occurredAt.millisecondsSinceEpoch;
    final clock = now.millisecondsSinceEpoch;
    if (authority['offline_enabled'] != true ||
        issued is! int ||
        expires is! int ||
        expires <= issued ||
        expires - issued > 86400000 ||
        clock < issued ||
        clock >= expires ||
        occurred < issued ||
        occurred >= expires ||
        occurred > clock + 300000) {
      throw StateError('offline_cashier.authority_expired');
    }
    final history = state['authority_history'];
    final known = history is Map ? history[command.permitId] : null;
    if (authority['protocol_version'] != 2 ||
        known is! Map ||
        !CashierAuthorityValidator.sameFacts(known, authority)) {
      throw StateError('offline_cashier.authority_review_required');
    }
  }

  static void _validateShift(Map state, LocalCashierCommand command) {
    final shift = state['shift'];
    if (shift is! Map ||
        shift['id'] != command.shiftId ||
        shift['lounge_id'] != command.loungeId ||
        shift['actor_id'] != command.actorId ||
        shift['status'] != 'open') {
      throw StateError('offline_cashier.shift_required');
    }
  }
}
