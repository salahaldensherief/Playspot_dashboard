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
    final copy = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(response)) as Map,
    );
    return journal.mutate(
      (state) => installInState(state, copy, deviceId: deviceId, mode: mode),
    );
  }

  /// Used by bootstrap so the permit and its resource snapshot commit together.
  Map<String, dynamic> installInState(
    Map<String, dynamic> state,
    Map<String, dynamic> response, {
    required String deviceId,
    required CashierConnectionMode mode,
    bool allowReleasedReclaim = false,
  }) {
    _ensureActive?.call();
    final release = state['writer_release'];
    if (release is Map &&
        (!allowReleasedReclaim ||
            release['status'] != 'released' ||
            (release['request'] as Map?)?['p_permit_id'] ==
                response['permit_id'])) {
      throw StateError('offline_cashier.release_pending');
    }
    final authority = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(response)) as Map,
    );
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
    _installSequence(state, authority, releasedReclaim: release is Map);
    if (previous != null && previous['protocol_version'] == 2) {
      history[previous['permit_id']] = CashierAuthorityValidator.immutableFacts(
        previous,
      );
    }
    history[authority['permit_id']] = CashierAuthorityValidator.immutableFacts(
      authority,
    );
    state['authority'] = authority;
    // Only a confirmed release followed by a fresh server-issued permit may
    // reopen commands. Pending/uncertain releases remain frozen across restarts.
    if (release is Map) state.remove('writer_release');
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

  void _installSequence(
    Map state,
    Map authority, {
    bool releasedReclaim = false,
  }) {
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
    if (releasedReclaim) {
      // Other authorized writers may have advanced the venue sequence since
      // this journal's confirmed release. Rebase only a fully drained journal
      // during complete bootstrap with a new server-issued permit.
      if (pending.isNotEmpty ||
          (state['sync_conflicts'] as Map? ?? {}).isNotEmpty ||
          state['authority_review_required'] == true ||
          expected <= 0 ||
          server < expected - 1) {
        throw StateError('offline_cashier.sequence_mismatch');
      }
      state['next_sequence'] = server + 1;
      return;
    }
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
