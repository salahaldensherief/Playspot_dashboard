import 'dart:convert';
import 'cashier_authority_validator.dart';
import 'cashier_writer_release_transport.dart';
import 'encrypted_cashier_journal.dart';
import 'cashier_lifecycle_gate.dart';

/// Freezes commands durably before sending a release; uncertain responses never
/// restore the old writer. A retry sends the exact same saved release request.
class CashierWriterReleaser {
  final EncryptedCashierJournal journal;
  final CashierWriterReleaseTransport transport;
  final void Function()? ensureActive;
  final CashierLifecycleGate lifecycle;
  Future<Map<String, dynamic>>? _running;
  bool _stopped = false;
  CashierWriterReleaser({
    required this.journal,
    required this.transport,
    this.ensureActive,
    CashierLifecycleGate? lifecycle,
  }) : lifecycle = lifecycle ?? CashierLifecycleGate();

  Future<Map<String, dynamic>> release() =>
      _running ??= lifecycle.run(_release).whenComplete(() => _running = null);

  Future<Map<String, dynamic>> _release() async {
    _checkActive();
    final frozen = await journal.mutate((state) {
      _checkActive();
      final previous = state['writer_release'];
      if (previous is Map) return Map<String, dynamic>.from(previous);
      if ((state['outbox'] as List).isNotEmpty ||
          (state['sync_conflicts'] as Map? ?? {}).isNotEmpty ||
          state['authority_review_required'] == true) {
        throw StateError('offline_cashier.release_pending_operations');
      }
      final authority = state['authority'];
      if (authority is! Map ||
          authority['actor_id'] != journal.actorId ||
          authority['lounge_id'] != journal.loungeId ||
          authority['offline_enabled'] != true) {
        throw StateError('offline_cashier.permission_denied');
      }
      final next = CashierAuthorityValidator.integer(state['next_sequence']);
      if (next <= 0) throw StateError('offline_cashier.sequence_mismatch');
      final request = <String, dynamic>{
        'p_lounge_id': journal.loungeId,
        'p_device_id': authority['device_id'],
        'p_permit_id': authority['permit_id'],
        'p_last_applied_sequence': next - 1,
      };
      final release = <String, dynamic>{
        'status': 'pending',
        'actor_id': journal.actorId,
        'request': request,
      };
      state['writer_release'] = release;
      return release;
    });
    if (frozen['status'] == 'released') {
      return Map<String, dynamic>.from(frozen['receipt'] as Map);
    }
    final request = Map<String, dynamic>.from(frozen['request'] as Map);
    final response = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(await transport.release(Map.of(request)))) as Map,
    );
    _checkActive();
    if (response['protocol_version'] != 2 ||
        response['released'] != true ||
        response['actor_id'] != journal.actorId ||
        response['lounge_id'] != request['p_lounge_id'] ||
        response['device_id'] != request['p_device_id'] ||
        response['permit_id'] != request['p_permit_id'] ||
        response['last_applied_sequence'] !=
            request['p_last_applied_sequence'] ||
        response['released_at'] is! String ||
        DateTime.tryParse(response['released_at'] as String) == null) {
      throw const FormatException('offline_cashier.invalid_release');
    }
    return journal.mutate((state) {
      _checkActive();
      final barrier = state['writer_release'];
      if (barrier is! Map || barrier['status'] != 'pending') {
        throw StateError('offline_cashier.release_pending');
      }
      barrier['status'] = 'released';
      barrier['receipt'] = response;
      return response;
    });
  }

  void stop() => _stopped = true;
  void _checkActive() {
    if (_stopped) throw StateError('offline_cashier.journal_closed');
    ensureActive?.call();
  }
}
