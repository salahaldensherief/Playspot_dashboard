import 'dart:convert';
import '../../domain/entities/cashier_connection_mode.dart';
import 'encrypted_cashier_journal.dart';
import 'cashier_authority_validator.dart';

class CashierAuthorityStore {
  final EncryptedCashierJournal journal;
  final DateTime Function() _clock;
  final void Function()? _ensureActive;
  CashierAuthorityStore(
    this.journal, {
    DateTime Function()? clock,
    void Function()? ensureActive,
  }) : _clock = clock ?? DateTime.now,
       _ensureActive = ensureActive;

  Future<Map<String, dynamic>> install(
    Map<String, dynamic> response, {
    required String deviceId,
    required CashierConnectionMode mode,
  }) {
    final authority = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(response)) as Map,
    );
    return journal.mutate((state) {
      _ensureActive?.call();
      CashierAuthorityValidator.validate(
        authority,
        actorId: journal.actorId,
        loungeId: journal.loungeId,
        deviceId: deviceId,
        mode: mode,
        now: _clock(),
      );
      final previous = state['authority'] as Map?;
      final history =
          state.putIfAbsent('authority_history', () => <String, dynamic>{})
              as Map;
      _assertImmutable(previous, history, authority);
      _installSequence(state, authority);
      if (previous != null && previous['protocol_version'] == 2) {
        history[previous['permit_id']] =
            CashierAuthorityValidator.immutableFacts(previous);
      }
      history[authority['permit_id']] =
          CashierAuthorityValidator.immutableFacts(authority);
      state['authority'] = authority;
      final pending = state['outbox'] as List;
      state['authority_review_required'] = pending.any(
        (op) =>
            op is! Map ||
            !CashierAuthorityValidator.isIssuedEvent(
              history[op['permit_id']],
              op,
            ),
      );
      return authority;
    });
  }

  void _assertImmutable(Map? previous, Map history, Map authority) {
    final previousGrant = previous == null
        ? null
        : history[previous['permit_id']];
    if (previous != null &&
        previousGrant is Map &&
        !CashierAuthorityValidator.sameFacts(previousGrant, previous)) {
      throw CashierAuthorityValidator.invalid;
    }
    final known = history[authority['permit_id']] as Map?;
    if ((known != null &&
            !CashierAuthorityValidator.sameFacts(known, authority)) ||
        (previous != null &&
            (previous['device_id'] != authority['device_id'] ||
                previous['actor_id'] != authority['actor_id'] ||
                previous['lounge_id'] != authority['lounge_id'])) ||
        (previous?['permit_id'] == authority['permit_id'] &&
            !CashierAuthorityValidator.sameFacts(previous ?? {}, authority)) ||
        (previous?['server_time_ms'] is num &&
            (previous?['server_time_ms'] as num) >
                authority['server_time_ms'])) {
      throw CashierAuthorityValidator.invalid;
    }
  }

  void _installSequence(Map state, Map authority) {
    final server = CashierAuthorityValidator.integer(
      authority['last_applied_sequence'],
    );
    if (server >= 9007199254740991) {
      throw StateError('offline_cashier.sequence_mismatch');
    }
    final pending = state['outbox'] as List;
    final next = state['next_sequence'];
    if (next == null && pending.isEmpty && (state['bookings'] as Map).isEmpty) {
      state['next_sequence'] = server + 1;
      return;
    }
    final expected = CashierAuthorityValidator.integer(next);
    if (expected <= 0 || server >= expected) {
      throw StateError('offline_cashier.sequence_mismatch');
    }
    if (pending.isEmpty) {
      if (server != expected - 1) {
        throw StateError('offline_cashier.sequence_mismatch');
      }
      return;
    }
    final head = pending.first;
    if (head is! Map) throw StateError('offline_cashier.sequence_mismatch');
    var sequence = CashierAuthorityValidator.integer(head['sequence']);
    if (sequence < 1 || server < sequence - 1) {
      throw StateError('offline_cashier.sequence_mismatch');
    }
    for (final operation in pending) {
      if (operation is! Map || operation['sequence'] != sequence++) {
        throw StateError('offline_cashier.sequence_mismatch');
      }
    }
    if (sequence != expected) {
      throw StateError('offline_cashier.sequence_mismatch');
    }
  }
}
