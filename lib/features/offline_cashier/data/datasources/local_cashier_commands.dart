import 'cashier_command_codec.dart';
import '../../domain/entities/local_cashier_command.dart';
import 'encrypted_cashier_journal.dart';
import 'local_cashier_booking_rules.dart';
import 'local_cashier_sale_rules.dart';

class LocalCashierCommands {
  final EncryptedCashierJournal journal;
  final DateTime Function() _clock;
  LocalCashierCommands(this.journal, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  Future<Map<String, dynamic>> execute(LocalCashierCommand command) {
    return journal.mutate((state) {
      final receipt = _serialize(command);
      final outbox = state['outbox'] as List;
      final receipts =
          state.putIfAbsent('receipts', () => <String, dynamic>{}) as Map;
      final old = receipts[command.id] as Map?;
      if (old != null) {
        final existing = Map<String, dynamic>.from(old)..remove('sequence');
        if (CashierCommandCodec.canonical(existing) !=
            CashierCommandCodec.canonical(receipt)) {
          throw StateError('offline_cashier.idempotency_conflict');
        }
        return Map<String, dynamic>.from(old);
      }
      _authorize(state, command);
      switch (command.kind) {
        case LocalCashierCommandKind.reserve:
          LocalCashierBookingRules.reserve(state, command);
        case LocalCashierCommandKind.start:
          LocalCashierBookingRules.start(state, command);
        case LocalCashierCommandKind.addItems:
          LocalCashierSaleRules.addItems(state, command);
        case LocalCashierCommandKind.collectCash:
          LocalCashierSaleRules.collectCash(state, command);
        case LocalCashierCommandKind.close:
          LocalCashierBookingRules.close(state, command);
      }
      final sequence = (state['next_sequence'] as int?) ?? 1;
      receipt['sequence'] = sequence;
      state['next_sequence'] = sequence + 1;
      receipts[command.id] = receipt;
      outbox.add(receipt);
      return receipt;
    });
  }

  Map<String, dynamic> _serialize(LocalCashierCommand command) => {
    'id': command.id,
    'booking_id': command.bookingId,
    'actor_id': command.actorId,
    'lounge_id': command.loungeId,
    'device_id': command.deviceId,
    'permit_id': command.permitId,
    'shift_id': command.shiftId,
    'occurred_at': command.occurredAt.toUtc().toIso8601String(),
    'kind': command.kind.name,
    'payload': command.payload,
  };

  void _authorize(Map<String, dynamic> state, LocalCashierCommand command) {
    final authority = state['authority'] as Map?;
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (!uuid.hasMatch(command.id) ||
        !uuid.hasMatch(command.bookingId) ||
        !uuid.hasMatch(command.deviceId) ||
        !uuid.hasMatch(command.shiftId) ||
        !uuid.hasMatch(command.permitId)) {
      throw StateError('offline_cashier.invalid_command');
    }
    if (authority == null ||
        authority['actor_id'] != command.actorId ||
        authority['lounge_id'] != command.loungeId ||
        authority['device_id'] != command.deviceId ||
        authority['permit_id'] != command.permitId ||
        authority['profile_active'] != true ||
        authority['profile_banned'] != false ||
        authority['lounge_status'] != 'active' ||
        authority['lounge_active'] != true) {
      throw StateError('offline_cashier.permission_denied');
    }
    final permissions = authority['permissions'] as Map? ?? const {};
    final now = _clock().millisecondsSinceEpoch;
    final issued = authority['issued_ms'];
    final expires = authority['expires_ms'];
    final occurred = command.occurredAt.millisecondsSinceEpoch;
    if (authority['offline_enabled'] != true ||
        issued is! int ||
        expires is! int ||
        expires <= issued ||
        now < issued ||
        now >= expires ||
        occurred < issued ||
        occurred > now + const Duration(minutes: 5).inMilliseconds) {
      throw StateError('offline_cashier.authority_expired');
    }
    final required = switch (command.kind) {
      LocalCashierCommandKind.reserve => 'bookings.manage',
      LocalCashierCommandKind.collectCash => 'billing_checkout',
      _ => 'sessions_control',
    };
    if (permissions[required] != true) {
      throw StateError('offline_cashier.permission_denied');
    }
    final shift = state['shift'] as Map?;
    if (shift == null ||
        shift['id'] != command.shiftId ||
        shift['lounge_id'] != command.loungeId ||
        shift['actor_id'] != command.actorId ||
        shift['status'] != 'open') {
      throw StateError('offline_cashier.shift_required');
    }
  }
}
