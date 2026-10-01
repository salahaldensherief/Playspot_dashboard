import '../../domain/entities/cashier_sync_result.dart';
import 'cashier_sync_transport.dart';
import 'encrypted_cashier_journal.dart';
import 'cashier_receipt_validator.dart';

class CashierOutboxSynchronizer {
  final EncryptedCashierJournal journal;
  final CashierSyncTransport transport;
  Future<CashierSyncResult>? _running;
  bool _stopped = false;
  CashierOutboxSynchronizer({required this.journal, required this.transport});

  Future<CashierSyncResult> synchronize() =>
      _running ??= _run().whenComplete(() => _running = null);

  Future<CashierSyncResult> _run() async {
    var applied = 0;
    while (true) {
      _checkActive();
      final state = await journal.read();
      final outbox = state['outbox'] as List;
      if (outbox.isEmpty) {
        return CashierSyncResult(appliedCount: applied, pendingCount: 0);
      }
      final operation = Map<String, dynamic>.from(outbox.first as Map);
      final conflicts = state['sync_conflicts'] as Map? ?? const {};
      if (conflicts.containsKey(operation['id'])) {
        return CashierSyncResult(
          appliedCount: applied,
          pendingCount: outbox.length,
          blockedOperationId: operation['id'] as String,
        );
      }
      final response = await transport.send(operation);
      _checkActive();
      CashierReceiptValidator.validate(operation, response);
      if (response['status'] == 'conflict') {
        await _persistConflict(operation, response);
        return CashierSyncResult(
          appliedCount: applied,
          pendingCount: outbox.length,
          blockedOperationId: operation['id'] as String,
        );
      }
      await _acknowledge(operation, response);
      applied++;
    }
  }

  Future<void> _persistConflict(Map operation, Map response) => journal.mutate((
    state,
  ) {
    final conflicts =
        state.putIfAbsent('sync_conflicts', () => <String, dynamic>{}) as Map;
    conflicts[operation['id']] = {'code': response['code']};
  });

  Future<void> _acknowledge(Map operation, Map response) => journal.mutate((
    state,
  ) {
    final pending = state['outbox'] as List;
    if (pending.isEmpty || (pending.first as Map)['id'] != operation['id']) {
      throw StateError('offline_cashier.outbox_changed');
    }
    pending.removeAt(0);
    final acknowledgements =
        state.putIfAbsent('acknowledgements', () => <String, dynamic>{}) as Map;
    acknowledgements[operation['id']] = response;
    final bookings =
        state.putIfAbsent('server_bookings', () => <String, dynamic>{}) as Map;
    bookings[operation['booking_id']] =
        CashierReceiptValidator.bookingProjection(operation, response);
  });

  void stop() => _stopped = true;

  void _checkActive() {
    if (_stopped) throw StateError('offline_cashier.journal_closed');
  }
}
