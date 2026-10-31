import 'cashier_command_codec.dart';
import '../../domain/entities/local_cashier_command.dart';
import 'encrypted_cashier_journal.dart';
import 'local_cashier_booking_rules.dart';
import 'local_cashier_sale_rules.dart';
import 'local_cashier_authority_rules.dart';

class LocalCashierCommands {
  final EncryptedCashierJournal journal;
  final DateTime Function() _clock;
  final void Function()? _ensureActive;
  final bool requireBootstrap;
  LocalCashierCommands(
    this.journal, {
    DateTime Function()? clock,
    void Function()? ensureActive,
    this.requireBootstrap = false,
  }) : _clock = clock ?? DateTime.now,
       _ensureActive = ensureActive;

  Future<Map<String, dynamic>> execute(LocalCashierCommand command) {
    return journal.mutate((state) {
      _ensureActive?.call();
      final receipt = _serialize(command);
      final outbox = state['outbox'] as List;
      final receipts =
          state.putIfAbsent('receipts', () => <String, dynamic>{}) as Map;
      final old = receipts[command.id] as Map?;
      if (old != null) {
        final existing = Map<String, dynamic>.from(old)
          ..remove('sequence')
          ..remove('quoted_items')
          ..remove('quoted_session')
          ..remove('quoted_total_minor');
        if (CashierCommandCodec.canonical(existing) !=
            CashierCommandCodec.canonical(receipt)) {
          throw StateError('offline_cashier.idempotency_conflict');
        }
        return Map<String, dynamic>.from(old);
      }
      LocalCashierAuthorityRules.authorize(
        state,
        command,
        actorId: journal.actorId,
        loungeId: journal.loungeId,
        now: _clock(),
      );
      if (requireBootstrap && state['bootstrap'] is! Map) {
        throw StateError('offline_cashier.bootstrap_required');
      }
      _applyCommand(state, command);
      final sequence = state['next_sequence'];
      if (sequence is! int || sequence < 1 || sequence >= 9007199254740991) {
        throw StateError('offline_cashier.sequence_mismatch');
      }
      _captureQuote(state, command, receipt);
      receipt['sequence'] = sequence;
      state['next_sequence'] = sequence + 1;
      receipts[command.id] = receipt;
      outbox.add(receipt);
      return receipt;
    });
  }

  void _applyCommand(Map<String, dynamic> state, LocalCashierCommand command) {
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
  }

  void _captureQuote(
    Map<String, dynamic> state,
    LocalCashierCommand command,
    Map<String, dynamic> receipt,
  ) {
    if (command.kind == LocalCashierCommandKind.collectCash) return;
    final booking = LocalCashierBookingRules.booking(state, command);
    if (command.kind == LocalCashierCommandKind.addItems) {
      final order = (booking['items'] as List).last as Map;
      receipt['quoted_items'] = order['items'];
    } else {
      receipt['quoted_session'] = {
        'room_id': booking['room_id'],
        'timezone': booking['timezone'],
        'start_ms': booking['start_ms'],
        'end_ms': booking['end_ms'],
        'started_ms': booking['started_ms'],
        'paid_minor': booking['paid_minor'],
      };
    }
    receipt['quoted_total_minor'] = booking['total_minor'];
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
}
